require 'bigbluebutton_api'

class BigbluebuttonServer < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  has_many :recordings,
           class_name: 'BigbluebuttonRecording',
           foreign_key: 'server_id',
           dependent: :destroy

  has_one :config,
          class_name: 'BigbluebuttonServerConfig',
          foreign_key: 'server_id',
          dependent: :destroy

  delegate :update_config, to: :config
  delegate :available_layouts, to: :config
  delegate :available_layouts_names, to: :config
  delegate :available_layouts_for_select, to: :config

  validates :name,
            :presence => true,
            :length => { :minimum => 1, :maximum => 500 }

  validates :url,
            :presence => true,
            :length => { :maximum => 500 },
            :format => { :with => /http[s]?:\/\/.*\/bigbluebutton\/api/,
                         :message => I18n.t('bigbluebutton_rails.servers.errors.url_format') }

  validates :param,
            :presence => true,
            :uniqueness => true,
            :length => { :minimum => 3 },
            :format => { :with => /\A[a-zA-Z\d_]+[a-zA-Z\d_-]*[a-zA-Z\d_]+\z/,
                         :message => I18n.t('bigbluebutton_rails.servers.errors.param_format') }

  validates :secret,
            :presence => true,
            :length => { :minimum => 1, :maximum => 500 }

  validates :version,
            :inclusion => { :in => ['0.8', '0.81', '0.9', '1.0'] },
            :allow_blank => true

  # Array of <tt>BigbluebuttonMeeting</tt>
  attr_reader :meetings

  after_initialize :init
  before_validation :set_param

  after_create :create_config
  after_create :update_config

  before_save :check_for_version_update
  after_update :check_for_config_update

  # Schedules a recording update right after a recording server is added.
  after_create do
    Resque.enqueue(::BigbluebuttonUpdateRecordings, self.id)
  end

  # In case there's no config created yet, build one.
  def config_with_initialize
    config_without_initialize || build_config(server: self)
  end
  alias_method_chain :config, :initialize

  # Helper to get the default server
  def self.default
    self.first
  end

  # Returns the API object (<tt>BigBlueButton::BigBlueButtonAPI</tt> defined in
  # <tt>bigbluebutton-api-ruby</tt>) associated with this server.
  def api
    return @api if @api.present?

    version = self.version
    version = set_api_version_from_server if version.blank?
    @api = BigBlueButton::BigBlueButtonApi.new(self.url, self.secret, version.to_s, true)
  end

  # Fetches the meetings currently created in the server (running or not).
  #
  # Using the response, updates <tt>meetings</tt> with a list of <tt>BigbluebuttonMeeting</tt>
  # objects.
  #
  # Triggers API call: <tt>getMeetings</tt>.
  def fetch_meetings
    response = self.api.get_meetings

    # updates the information in the rooms that are currently in BBB
    @meetings = []
    response[:meetings].each do |attr|
      room = BigbluebuttonRoom.find_by(meetingid: attr[:meetingID])
      # TODO: there might be more attributes returned by the API, review them all
      if room.nil?
        attrs = {
          meetingid: attr[:meetingID],
          name: attr[:meetingID],
          attendee_api_password: attr[:attendeePW],
          moderator_api_password: attr[:moderatorPW],
          external: true,
          private: true
        }
        room = BigbluebuttonRoom.new(attrs)
      else
        room.update_attributes(attendee_api_password: attr[:attendeePW],
                               moderator_api_password: attr[:moderatorPW])
      end
      room.running = attr[:running]
      room.update_current_meeting_record

      @meetings << room
    end
  end

  # Sends a call to the BBB server to publish or unpublish a recording or a set
  # of recordings.
  # ids:: IDs of the recordings that will be affected. Accepts the same format
  #       accepted by BigBlueButtonApi::publish_recordings
  # publish:: Publish or unpublish the recordings?
  #
  # Triggers API call: <tt>publishRecordings</tt>.
  def send_publish_recordings(ids, publish)
    self.api.publish_recordings(ids, publish)

    # Update #published in all recordings
    ids = ids.split(",") if ids.instance_of?(String) # "id1,id2" to ["id1", "id2"]
    ids.each do |id|
      recording = BigbluebuttonRecording.find_by_recordid(id.strip)
      recording.update_attributes(:published => publish) unless recording.nil?
    end
  end

  # Sends a call to the BBB server to delete a recording or a set or recordings.
  # ids:: IDs of the recordings that will be affected. Accepts the same format
  #       accepted by BigBlueButtonApi::delete_recordings
  #
  # Triggers API call: <tt>deleteRecordings</tt>.
  def send_delete_recordings(ids)
    self.api.delete_recordings(ids)
  end

  # Sends a call to the BBB server to get the list of recordings and updates
  # the database with these recordings.
  # filter:: filters to be used, uses the same format accepted by
  #          BigBlueButtonApi::get_recordings. Can filter by meetingID and/or
  #          metadata values.
  #
  # Triggers API call: <tt>getRecordings</tt>.
  def fetch_recordings(filter=nil, full_sync=false)
    filter ||= {}
    logger.info "Fetching recordings for the server #{self.inspect} with filter: #{filter.inspect}"
    recordings = self.api.get_recordings(filter)
    if recordings and recordings[:recordings]
      BigbluebuttonRecording.sync(self, recordings[:recordings], full_sync)
    end
  end

  def to_param
    self.param
  end

  def set_api_version_from_server
    begin
      # creating the object with version=nil makes the gem fetch the version from the server
      api = BigBlueButton::BigBlueButtonApi.new(self.url, self.secret, nil, false)
      self.version = api.version
    rescue BigBlueButton::BigBlueButtonException
      # we just ignore errors in case the server is not responding
      # in these cases, the version will be fetched later on
      Rails.logger.error "Could not fetch the API version from the server #{self.id}. The URL probably incorrect."
      self.version = nil
    end
    self.version
  end

  # Returns the URL to the <tt>/check</tt> request in the server.
  def check_url
    self.api.check_url
  end

  protected

  def init
    # fetched attributes
    @meetings = []
  end

  # if :param wasn't set, sets it as :name downcase and parameterized
  def set_param
    if self.param.blank?
      self.param = self.name.parameterize.downcase unless self.name.nil?
    end
  end

  def create_config
    BigbluebuttonServerConfig.create(server: self)
  end

  # Checks if we have to update the server version or not and do it if needed.
  # If the user only changes the version, we assume he's trying to force an API version.
  # If the user changes url/secret and the version, we also assume that he wants
  # to force the API version
  def check_for_version_update
    if [:url, :secret, :version].any? { |k| self.changes.key?(k) }
      self.set_api_version_from_server
    end
  end

  def check_for_config_update
    if [:url, :secret, :version].any?{ |k| self.changes.key?(k) }
      self.update_config
    end
  end

end
