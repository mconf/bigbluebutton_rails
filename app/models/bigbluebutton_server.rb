require 'bigbluebutton_api'

class BigbluebuttonServer < ActiveRecord::Base
  has_many :rooms,
           :class_name => 'BigbluebuttonRoom',
           :foreign_key => 'server_id',
           :dependent => :nullify

  validates :name,
            :presence => true,
            :uniqueness => true,
            :length => { :minimum => 1, :maximum => 500 }

  validates :url,
            :presence => true,
            :uniqueness => true,
            :length => { :maximum => 500 },
            :format => { :with => /http:\/\/.*\/bigbluebutton\/api/,
                         :message => I18n.t('bigbluebutton_rails.servers.errors.url_format') }

  validates :param,
            :presence => true,
            :uniqueness => true,
            :length => { :minimum => 3 },
            :format => { :with => /^[a-zA-Z\d_]+[a-zA-Z\d_-]*[a-zA-Z\d_]+$/,
                         :message => I18n.t('bigbluebutton_rails.servers.errors.param_format') }

  validates :salt,
            :presence => true,
            :length => { :minimum => 1, :maximum => 500 }

  validates :version,
            :presence => true,
            :inclusion => { :in => ['0.7', '0.8'] }

  attr_accessible :name, :url, :version, :salt, :param

  # Array of <tt>BigbluebuttonMeeting</tt>
  attr_reader :meetings

  after_initialize :init
  before_validation :set_param

  # Returns the API object (<tt>BigBlueButton::BigBlueButtonAPI</tt> defined in
  # <tt>bigbluebutton-api-ruby</tt>) associated with this server.
  def api
    if @api.nil?
      @api = BigBlueButton::BigBlueButtonApi.new(self.url, self.salt,
                                                 self.version.to_s, false)
    end
    @api
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
      room = BigbluebuttonRoom.find_by_server_id_and_meetingid(self.id, attr[:meetingID])
      if room.nil?
        room = BigbluebuttonRoom.new(:server => self, :meetingid => attr[:meetingID],
                                     :name => attr[:meetingID], :attendee_password => attr[:attendeePW],
                                     :moderator_password => attr[:moderatorPW], :external => true,
                                     :randomize_meetingid => false, :private => true)
      else
        room.update_attributes(:attendee_password => attr[:attendeePW],
                               :moderator_password => attr[:moderatorPW])
      end
      room.running = attr[:running]

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
  # ids:: meetingIDs of the recordings to be filtered, uses the same format
  #       accepted by BigBlueButtonApi::get_recordings
  #
  # Triggers API call: <tt>getRecordings</tt>.
  def fetch_recordings(ids)
    recordings = self.api.get_recordings(ids)
    if recordings and recordings[:recordings]
      BigbluebuttonRecording.sync(self, recordings[:recordings])
    end
  end

  def to_param
    self.param
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

end
