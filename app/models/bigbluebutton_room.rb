class BigbluebuttonRoom < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :owner, polymorphic: true

  has_many :recordings,
           class_name: 'BigbluebuttonRecording',
           foreign_key: 'room_id',
           dependent: :nullify

  has_many :metadata,
           class_name: 'BigbluebuttonMetadata',
           as: :owner,
           dependent: :destroy,
           inverse_of: :owner

  has_one :room_options,
          class_name: 'BigbluebuttonRoomOptions',
          foreign_key: 'room_id',
          autosave: true,
          dependent: :destroy

  delegate :default_layout, :default_layout=, :to => :room_options
  delegate :presenter_share_only, :presenter_share_only=, :to => :room_options
  delegate :auto_start_video, :auto_start_video=, :to => :room_options
  delegate :auto_start_audio, :auto_start_audio=, :to => :room_options
  delegate :background, :background=, :to => :room_options

  accepts_nested_attributes_for :metadata,
    :allow_destroy => true,
    :reject_if => :all_blank

  validates :meetingid, :presence => true, :uniqueness => true,
    :length => { :minimum => 1, :maximum => 100 }
  validates :name, :presence => true,
    :length => { :minimum => 1, :maximum => 150 }
  validates :welcome_msg, :length => { :maximum => 250 }
  validates :private, :inclusion => { :in => [true, false] }
  validates :record_meeting, :inclusion => { :in => [true, false] }

  validates :duration,
    :presence => true,
    :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }

  validates :param,
            :presence => true,
            :uniqueness => true,
            :length => { :minimum => 1 },
            :format => { :with => /\A([a-zA-Z\d_]|[a-zA-Z\d_]+[a-zA-Z\d_-]*[a-zA-Z\d_]+)\z/,
                         :message => I18n.t('bigbluebutton_rails.rooms.errors.param_format') }

  # Passwords are 16 character strings
  # See http://groups.google.com/group/bigbluebutton-dev/browse_thread/thread/9be5aae1648bcab?pli=1
  validates :attendee_key, :length => { :maximum => 16 }
  validates :moderator_key, :length => { :maximum => 16 }

  validates :attendee_key, :presence => true, :if => :private?
  validates :moderator_key, :presence => true, :if => :private?

  # Note: these params need to be fetched from the server before being accessed
  attr_accessor :running, :participant_count, :moderator_count, :attendees,
                :has_been_forcibly_ended, :start_time, :end_time

  after_initialize :init
  after_create :create_room_options
  before_validation :set_param
  before_validation :set_keys

  # the full logout_url used when logout_url is a relative path
  attr_accessor :full_logout_url

  # HTTP headers that will be passed to the BigBlueButtonApi object to send
  # in all GET/POST requests to a webconf server.
  # Currently used to send the client's IP to the load balancer.
  attr_accessor :request_headers

  # In case there's no room_options created yet, build one
  # (happens usually when an old database is migrated).
  def room_options_with_initialize
    room_options_without_initialize || build_room_options
  end
  alias_method_chain :room_options, :initialize

  # Convenience method to access the attribute <tt>running</tt>
  def is_running?
    @running
  end

  # Fetches info from BBB about this room.
  # The response is parsed and stored in the model. You can access it using attributes such as:
  #
  #   room.participant_count
  #   room.attendees[0].full_name
  #
  # The attributes changed are:
  # * <tt>participant_count</tt>
  # * <tt>moderator_count</tt>
  # * <tt>running</tt>
  # * <tt>has_been_forcibly_ended</tt>
  # * <tt>start_time</tt>
  # * <tt>end_time</tt>
  # * <tt>attendees</tt> (array of <tt>BigbluebuttonAttendee</tt>)
  #
  # Triggers API call: <tt>getMeetingInfo</tt>.
  def fetch_meeting_info
    begin
      server = select_server(:get_meeting_info)
      response = server.api.get_meeting_info(self.meetingid, self.moderator_api_password)

      @participant_count = response[:participantCount]
      @moderator_count = response[:moderatorCount]
      @running = response[:running]
      @has_been_forcibly_ended = response[:hasBeenForciblyEnded]
      @start_time = response[:startTime]
      @end_time = response[:endTime]
      @attendees = []
      if response[:attendees].present?
        response[:attendees].each do |att|
          attendee = BigbluebuttonAttendee.new
          attendee.from_hash(att)
          @attendees << attendee
        end
      end

      # a 'shortcut' to update meetings since we have all information we need
      # if we got here, it means the meeting is still in the server, so it's not ended
      self.update_attributes(create_time: response[:createTime]) unless self.new_record?
      self.update_current_meeting_record(response[:metadata], true)

    rescue BigBlueButton::BigBlueButtonException => e
      # note: we could catch only the 'notFound' error, but there are complications, so
      # it's better to end the meeting prematurely and open it again if needed than to
      # not end it at all (e.g. in case the server stops responding)
      Rails.logger.info "BigbluebuttonRoom: detected that a meeting ended in the room #{self.meetingid} after the error #{e.inspect}"

      self.update_attributes(create_time: nil) unless self.new_record?
      self.finish_meetings
    end

    response
  end

  # Fetches the BBB server to see if the meeting is running. Sets <tt>running</tt>
  #
  # Triggers API call: <tt>isMeetingRunning</tt>.
  def fetch_is_running?
    server = select_server(:is_meeting_running)
    @running = server.api.is_meeting_running?(self.meetingid)
  end

  # Sends a call to the BBB server to end the meeting.
  #
  # Triggers API call: <tt>end</tt>.
  def send_end
    server = select_server(:end)
    response = server.api.end_meeting(self.meetingid, self.moderator_api_password)

    # enqueue an update in the meeting to end it faster
    Resque.enqueue(::BigbluebuttonMeetingUpdater, self.id)

    response
  end

  # Sends a call to the BBB server to create the meeting.
  # 'user' is the object that represents the user that is creating the meeting.
  # 'user_opts' is a hash of parameters to override the parameters sent in the create
  #   request. Can be passed by the application to enforce some values over the values
  #   that are taken from the database.
  #
  # With the response, updates the following attributes:
  # * <tt>attendee_api_password</tt>
  # * <tt>moderator_api_password</tt>
  #
  # Triggers API call: <tt>create</tt>.
  def send_create(user=nil, user_opts={})
    self.meetingid = unique_meetingid() if self.meetingid.blank?
    self.moderator_api_password = internal_password() if self.moderator_api_password.blank?
    self.attendee_api_password = internal_password() if self.attendee_api_password.blank?
    self.save unless self.new_record?

    response = internal_create_meeting(user, user_opts)
    unless response.nil?
      self.attendee_api_password = response[:attendeePW]
      self.moderator_api_password = response[:moderatorPW]
      self.create_time = response[:createTime]
      self.voice_bridge = response[:voiceBridge] if response.has_key?(:voiceBridge)

      unless self.new_record?
        self.save

        # creates the meeting object since the create was successful
        create_meeting_record(response[:metadata])

        # enqueue an update in the meeting with a small delay we assume to be
        # enough for the user to fully join the meeting
        Resque.enqueue(::BigbluebuttonMeetingUpdater, self.id, 10.seconds)
      end
    end

    response
  end

  # Returns the URL to join this room.
  # username:: Name of the user
  # role:: Role of the user in this room. Can be <tt>[:moderator, :attendee]</tt>
  # key:: Key to be use (in case role == nil)
  # options:: Additional options to use when generating the URL
  #
  # Uses the API but does not require a request to the server.
  def join_url(username, role, key=nil, options={})
    server = select_server(:join_meeting_url)

    pass = case role
           when :moderator
             self.moderator_api_password
           when :attendee
             self.attendee_api_password
           when :guest
             if BigbluebuttonRails.guest_support
               options = { guest: true }.merge(options)
             end
             self.attendee_api_password
           else
             map_key_to_internal_password(key)
           end

    r = server.api.join_meeting_url(self.meetingid, username, pass, options)
    r.strip! unless r.nil?
    r
  end


  # Returns the role of the user based on the key given.
  # The return value can be <tt>:moderator</tt>, <tt>:attendee</tt>, or
  # nil if the key given does not match any of the room keys.
  # params:: Hash with a key :key
  def user_role(params)
    role = nil
    if params && params.has_key?(:key)
      if self.moderator_key == params[:key]
        role = :moderator
      elsif self.attendee_key == params[:key]
        role = :attendee
      end
    end
    role
  end

  # Compare the instance variables of two models to define if they are equal
  # Returns a hash with the variables with different values or an empty hash
  # if they are have all equal values.
  # From: http://alicebobandmallory.com/articles/2009/11/02/comparing-instance-variables-in-ruby
  def instance_variables_compare(o)
    vars = [ :@running, :@participant_count, :@moderator_count, :@attendees,
             :@has_been_forcibly_ended, :@start_time, :@end_time ]
    Hash[*vars.map { |v|
           self.instance_variable_get(v)!=o.instance_variable_get(v) ?
           [v,o.instance_variable_get(v)] : []}.flatten]
  end

  # A more complete equal? method, comparing also the attibutes and
  # the instance variables
  def attr_equal?(o)
    self == o and
      self.instance_variables_compare(o).empty? and
      self.attributes == o.attributes
  end

  def to_param
    self.param
  end

  # The create logic.
  # Will create the meeting in this room unless it is already running.
  # Returns true if the meeting was created.
  def create_meeting(user=nil, request=nil, user_opts={})
    fetch_is_running?
    unless is_running?

      # in case the meeting is not running but it's still in memory
      suppress(BigBlueButton::BigBlueButtonException) { send_end }

      add_domain_to_logout_url(request.protocol, request.host_with_port) unless request.nil?
      send_create(user, user_opts)
      true
    else
      false
    end
  end

  # add a domain name and/or protocol to the logout_url if needed
  # it doesn't save in the db, just updates the instance
  def add_domain_to_logout_url(protocol, host)
    unless logout_url.nil?
      url = logout_url.downcase
      unless url.nil? or url =~ /^[a-z]+:\/\//           # matches the protocol
        unless url =~ /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*/  # matches the host domain
          url = host + url
        end
        url = protocol + url
      end
      self.full_logout_url = url.downcase
    end
  end

  def unique_meetingid
    # GUID
    # Has to be globally unique in case more that one bigbluebutton_rails application is using
    # the same web conference server.
    "#{SecureRandom.uuid}-#{Time.now.to_i}"
  end

  # Returns the current meeting running on this room, if any.
  def get_current_meeting
    unless self.create_time.nil?
      BigbluebuttonMeeting.find_by(room_id: self.id, create_time: self.create_time)
    else
      nil
    end
  end

  # Updates the current meeting associated with this room
  def update_current_meeting_record(metadata=nil, force_not_ended=false)
    unless self.create_time.nil?
      attrs = {
        :running => self.running,
        :start_time => self.start_time.try(:utc)
      }
      # note: it's important to update the 'ended' attr so the meeting is
      # reopened in case it was mistakenly considered as ended
      attrs[:ended] = false if force_not_ended

      unless metadata.nil?
        begin
          attrs[:creator_id] = metadata[BigbluebuttonRails.metadata_user_id].to_i
          attrs[:creator_name] = metadata[BigbluebuttonRails.metadata_user_name]
        rescue
          attrs[:creator_id] = nil
          attrs[:creator_name] = nil
        end
      end

      meeting = self.get_current_meeting
      meeting.update_attributes(attrs) if meeting.present?
    end
  end

  def create_meeting_record(metadata=nil)
    unless get_current_meeting.present?
      if self.create_time.present?

        # to make sure there's no other meeting related to this room that
        # has not yet been set as ended
        self.finish_meetings

        server = select_server
        attrs = {
          room: self,
          server_url: server.url,
          server_secret: server.secret,
          meetingid: self.meetingid,
          name: self.name,
          recorded: self.record_meeting,
          create_time: self.create_time,
          running: self.running,
          ended: false,
          start_time: self.start_time.try(:utc)
        }
        unless metadata.nil?
          begin
            attrs[:creator_id] = metadata[BigbluebuttonRails.metadata_user_id].to_i
            attrs[:creator_name] = metadata[BigbluebuttonRails.metadata_user_name]
          rescue
            attrs[:creator_id] = nil
            attrs[:creator_name] = nil
          end
        end
        BigbluebuttonMeeting.create(attrs)

        Rails.logger.error "Did not create a current meeting because there was no create_time on room #{self.meetingid}"
      else
        Rails.logger.error "Did not create a current meeting because there was no create_time on room #{self.meetingid}"
      end
    end
  end

  # Sets all meetings related to this room as not running
  def finish_meetings
    BigbluebuttonMeeting.where(ended: false)
      .where(room_id: self.id)
      .update_all(running: false, ended: true)

    # in case there are inconsistent meetings marked as running
    # but that already ended
    BigbluebuttonMeeting.where(running: true, ended: true)
      .where(room_id: self.id)
      .update_all(running: false, ended: true)
  end

  # Gets a 'configToken' to use when joining the room.
  # Returns a string with the token generated or nil if there's no need
  # for a token (the options set in the room are the default options or there
  # are no options set in the room) or if an error occurred.
  #
  # The entire process consists in these steps:
  # * Go to the server get the default config.xml;
  # * Modify the config.xml based on the room options set in the room;
  # * Go to the server set the new config.xml;
  # * Get the token identifier and return it.
  #
  # Triggers API call: <tt>getDefaultConfigXML</tt>.
  # Triggers API call: <tt>setConfigXML</tt>.
  def fetch_new_token
    if self.room_options.is_modified?
      server = select_server(:set_config_xml)

      # get the default XML we will use to create a new one
      config_xml = server.api.get_default_config_xml

      # set the options on the XML
      # returns true if something was changed
      config_xml = self.room_options.set_on_config_xml(config_xml)
      if config_xml
        server.update_config(config_xml)
        # get the new token for the room, and return it
        server.api.set_config_xml(self.meetingid, config_xml)
      else
        nil
      end
    else
      nil
    end
  end

  def available_layouts
    server = select_server
    server.present? ? server.available_layouts : []
  end

  def available_layouts_names
    server = select_server
    server.present? ? server.available_layouts_names : []
  end

  def available_layouts_for_select
    server = select_server
    server.present? ? server.available_layouts_for_select : []
  end

  # Generates a new dial number following `pattern` and saves it in the room, returning
  # the results of `update_attributes`.
  # Will always generate a unique number. Tries several times if the number already
  # exists and returns `nil` in case it wasn't possible to generate a unique value.
  def generate_dial_number!(pattern=nil)
    pattern ||= 'xxxx-xxxx'
    20.times do
      dn = BigbluebuttonRails::DialNumber.randomize(pattern)
      if BigbluebuttonRoom.where(dial_number: dn).empty?
        return self.update_attributes(dial_number: dn)
      end
    end
    nil
  end

  def fetch_recordings(filter={})
    server = select_server(:get_recordings)
    if server.present?
      server.fetch_recordings(filter.merge({ meetingID: self.meetingid }))
      true
    else
      false
    end
  end

  # Selects a server to be used by this room whenever it needs to make API calls.
  # By default, if no servers are available an exception is raised.
  #
  # This method can be overwritten to change the way the server is selected
  # before a room is used. `api_method` contains the API method that is being
  # called. Any server returned here will be used. It *must* return a server,
  # otherwise the API calls will fail and the code will probably break.
  #
  # One good example is to always select a new server when a meeting is being
  # created (in case `api_method` is `:create`), making this a simple load
  # balancing tool that can work well in simple cases.
  def select_server(api_method=nil)
    server = BigbluebuttonServer.first
    if server.nil?
      msg = I18n.t('bigbluebutton_rails.rooms.errors.server.nil')
      raise BigbluebuttonRails::ServerRequired.new(msg)
    end
    server
  end

  protected

  def create_room_options
    BigbluebuttonRoomOptions.create(:room => self)
  end

  def init
    self[:meetingid] ||= unique_meetingid

    @request_headers = {}

    # fetched attributes
    @participant_count = 0
    @moderator_count = 0
    @running = false
    @has_been_forcibly_ended = false
    @start_time = nil
    @end_time = nil
    @attendees = []
  end

  def internal_create_meeting(user=nil, user_opts={})
    opts = {
      :record => self.record_meeting,
      :duration => self.duration,
      :moderatorPW => self.moderator_api_password,
      :attendeePW => self.attendee_api_password,
      :welcome => self.welcome_msg.blank? ? default_welcome_message : self.welcome_msg,
      :dialNumber => self.dial_number,
      :logoutURL => self.full_logout_url || self.logout_url,
      :maxParticipants => self.max_participants,
      :moderatorOnlyMessage => self.moderator_only_message,
      :autoStartRecording => self.auto_start_recording,
      :allowStartStopRecording => self.allow_start_stop_recording
    }.merge(user_opts)

    # Set the voice bridge only if the gem is configured to do so and the voice bridge
    # is not blank.
    if BigbluebuttonRails.use_local_voice_bridges && !self.voice_bridge.blank?
      opts.merge!({ :voiceBridge => self.voice_bridge })
    end

    opts.merge!(self.get_metadata_for_create)

    # Add information about the user that is creating the meeting (if any)
    unless user.nil?
      userid = user.send(BigbluebuttonRails.user_attr_id)
      username = user.send(BigbluebuttonRails.user_attr_name)
      opts.merge!({ "meta_#{BigbluebuttonRails.metadata_user_id}" => userid })
      opts.merge!({ "meta_#{BigbluebuttonRails.metadata_user_name}" => username })
    end

    # Add the invitation URL, if any
    invitation_url = self.try(BigbluebuttonRails.invitation_url_method)
    unless invitation_url.nil?
      opts.merge!({ "meta_#{BigbluebuttonRails.metadata_invitation_url}" => invitation_url })
    end

    server = select_server(:create)
    server.api.request_headers = @request_headers # we need the client's IP
    response = server.api.create_meeting(self.name, self.meetingid, opts)

    response
  end

  # Returns the default welcome message to be shown in a conference in case
  # there's no message set in this room.
  # Can be used to easily set a default message format for all rooms.
  def default_welcome_message
    if self.dial_number.present?
      I18n.t('bigbluebutton_rails.rooms.default_welcome_msg_dial_number')
    else
      I18n.t('bigbluebutton_rails.rooms.default_welcome_msg')
    end
  end

  # if :param wasn't set, sets it as :name downcase and parameterized
  def set_param
    if self.param.blank?
      self.param = self.name.parameterize.downcase unless self.name.nil?
    end
  end

  # When setting a room as private we generate keys in case they don't exist.
  def set_keys
    if self.private_changed? and self.private
      if self.moderator_key.blank?
        self.moderator_key = SecureRandom.hex(4)
      end
      if self.attendee_key.blank?
        self.attendee_key = SecureRandom.hex(4)
      end
    end
  end

  def get_metadata_for_create
    metadata = self.metadata.inject({}) { |result, meta|
      result["meta_#{meta.name}"] = meta.content; result
    }

    dynamic_metadata = self.try(BigbluebuttonRails.dynamic_metadata_method)
    unless dynamic_metadata.blank?
      metadata = self.dynamic_metadata.inject(metadata) { |result, meta|
        result["meta_#{meta[0]}"] = meta[1]; result
      }
    end

    metadata
  end

  private

  def internal_password
    SecureRandom.uuid
  end

  def map_key_to_internal_password(key)
    if key == self.attendee_key
      self.attendee_api_password
    elsif key == self.moderator_key
      self.moderator_api_password
    else
      nil
    end
  end

end
