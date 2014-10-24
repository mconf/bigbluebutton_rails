class BigbluebuttonRoom < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :server, :class_name => 'BigbluebuttonServer'
  belongs_to :owner, :polymorphic => true

  has_many :recordings,
           :class_name => 'BigbluebuttonRecording',
           :foreign_key => 'room_id',
           :dependent => :nullify

  has_many :metadata,
           :class_name => 'BigbluebuttonMetadata',
           :as => :owner,
           :dependent => :destroy,
           :inverse_of => :owner

  has_one :room_options,
          :class_name => 'BigbluebuttonRoomOptions',
          :foreign_key => 'room_id',
          :autosave => true,
          :dependent => :destroy

  delegate :default_layout, :default_layout=, :to => :room_options
  delegate :presenter_share_only, :presenter_share_only=, :to => :room_options
  delegate :auto_start_video, :auto_start_video=, :to => :room_options
  delegate :auto_start_audio, :auto_start_audio=, :to => :room_options
  delegate :get_available_layouts, :to => :room_options

  accepts_nested_attributes_for :metadata,
    :allow_destroy => true,
    :reject_if => :all_blank

  validates :meetingid, :presence => true, :uniqueness => true,
    :length => { :minimum => 1, :maximum => 100 }
  validates :name, :presence => true,
    :length => { :minimum => 1, :maximum => 150 }
  validates :welcome_msg, :length => { :maximum => 250 }
  validates :private, :inclusion => { :in => [true, false] }
  validates :voice_bridge, :presence => true, :uniqueness => true
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
    require_server

    response = self.server.api.get_meeting_info(self.meetingid, self.moderator_api_password)

    @participant_count = response[:participantCount]
    @moderator_count = response[:moderatorCount]
    @running = response[:running]
    @has_been_forcibly_ended = response[:hasBeenForciblyEnded]
    @start_time = response[:startTime]
    @end_time = response[:endTime]
    @attendees = []
    response[:attendees].each do |att|
      attendee = BigbluebuttonAttendee.new
      attendee.from_hash(att)
      @attendees << attendee
    end

    # a 'shortcut' to update meetings since we have all information we need
    update_current_meeting(response[:metadata])

    response
  end

  # Fetches the BBB server to see if the meeting is running. Sets <tt>running</tt>
  #
  # Triggers API call: <tt>isMeetingRunning</tt>.
  def fetch_is_running?
    require_server
    @running = self.server.api.is_meeting_running?(self.meetingid)
  end

  # Sends a call to the BBB server to end the meeting.
  #
  # Triggers API call: <tt>end</tt>.
  def send_end
    require_server
    response = self.server.api.end_meeting(self.meetingid, self.moderator_api_password)

    # enqueue an update in the meetings for later on
    Resque.enqueue(::BigbluebuttonMeetingUpdater, self.id, 15.seconds)

    response
  end

  # Sends a call to the BBB server to create the meeting.
  # 'user' is the object that represents the user that is creating the meeting.
  # 'user_opts' is a hash of parameters to override the parameters sent in the create
  #   request. Can be passed by the application to enforce some values over the values
  #   that are taken from the database.
  #
  # Will trigger 'select_server' to select a server where the meeting
  # will be created. If a server is selected, the model is saved.
  #
  # With the response, updates the following attributes:
  # * <tt>attendee_api_password</tt>
  # * <tt>moderator_api_password</tt>
  #
  # Triggers API call: <tt>create</tt>.
  def send_create(user=nil, user_opts={})
    # updates the server whenever a meeting will be created and guarantees it has a meetingid
    self.server = select_server
    self.meetingid = unique_meetingid() if self.meetingid.blank?
    self.moderator_api_password = internal_password() if self.moderator_api_password.blank?
    self.attendee_api_password = internal_password() if self.attendee_api_password.blank?
    self.save unless self.new_record?
    require_server

    response = internal_create_meeting(user, user_opts)
    unless response.nil?
      self.attendee_api_password = response[:attendeePW]
      self.moderator_api_password = response[:moderatorPW]
      self.create_time = response[:createTime]
      self.save unless self.new_record?
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
    require_server

    case role
    when :moderator
      r = self.server.api.join_meeting_url(self.meetingid, username, self.moderator_api_password, options)
    when :attendee
      r = self.server.api.join_meeting_url(self.meetingid, username, self.attendee_api_password, options)
    else
      r = self.server.api.join_meeting_url(self.meetingid, username, map_key_to_internal_password(key), options)
    end

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
    unless self.start_time.nil?
      BigbluebuttonMeeting.find_by_room_id_and_start_time(self.id, self.start_time.utc)
    else
      nil
    end
  end

  # Updates the current meeting associated with this room
  def update_current_meeting(metadata=nil)
    unless self.start_time.nil?
      attrs = {
        :server => self.server,
        :meetingid => self.meetingid,
        :name => self.name,
        :recorded => self.record_meeting,
        :running => self.running
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

      meeting = self.get_current_meeting
      if !meeting.nil?
        meeting.update_attributes(attrs)

      # only create a new meeting if it is running
      elsif self.running
        attrs.merge!({ :room => self, :start_time => self.start_time.utc })
        meeting = BigbluebuttonMeeting.create(attrs)

      end
    else
      # TODO: not enough information to find the meeting, do what?
    end
  end

  # Sets all meetings related to this room as not running
  def finish_meetings
    BigbluebuttonMeeting.where(running: true)
      .where(room_id: self.id)
      .update_all(running: false)
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

      # get the default XML we will use to create a new one
      config_xml = self.server.api.get_default_config_xml

      # set the options on the XML
      # returns true if something was changed
      config_xml = self.room_options.set_on_config_xml(config_xml)
      if config_xml

        # get the new token for the room, and return it
        self.server.api.set_config_xml(self.meetingid, config_xml)
      else
        nil
      end
    else
      nil
    end
  end

  protected

  def create_room_options
    BigbluebuttonRoomOptions.create(:room => self)
  end

  # Every room needs a server to be used.
  # The server of a room can change during the room's lifespan, but
  # it should not change if the room is running or if it was created
  # but not yet ended.
  # Any action that requires a server should call 'require_server' before
  # anything else.
  def require_server
    if self.server.nil?
      msg = I18n.t('bigbluebutton_rails.rooms.errors.server.not_set')
      raise BigbluebuttonRails::ServerRequired.new(msg)
    end
  end

  # This method can be overridden to change the way the server is selected
  # before a room is created
  # This one selects the server with less rooms in it
  def select_server
    BigbluebuttonServer.
      select("bigbluebutton_servers.*, count(bigbluebutton_rooms.id) as room_count").
      joins(:rooms).group(:server_id).order("room_count ASC").first
  end

  def init
    self[:meetingid] ||= unique_meetingid
    self[:voice_bridge] ||= random_voice_bridge

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

  def random_voice_bridge
    value = (70000 + SecureRandom.random_number(9999)).to_s
    count = 1
    while not BigbluebuttonRoom.find_by_voice_bridge(value).nil? and count < 10
      count += 1
      value = (70000 + SecureRandom.random_number(9999)).to_s
    end
    value
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
      :voiceBridge => self.voice_bridge
    }.merge(user_opts)

    opts.merge!(self.get_metadata_for_create)

    # Add information about the user that is creating the meeting (if any)
    unless user.nil?
      userid = user.send(BigbluebuttonRails.user_attr_id)
      username = user.send(BigbluebuttonRails.user_attr_name)
      opts.merge!({ "meta_#{BigbluebuttonRails.metadata_user_id}" => userid })
      opts.merge!({ "meta_#{BigbluebuttonRails.metadata_user_name}" => username })
    end

    self.server.api.request_headers = @request_headers # we need the client's IP
    response = self.server.api.create_meeting(self.name, self.meetingid, opts)

    # enqueue an update in the meetings to start now
    Resque.enqueue(::BigbluebuttonMeetingUpdater, self.id)

    response
  end

  # Returns the default welcome message to be shown in a conference in case
  # there's no message set in this room.
  # Can be used to easily set a default message format for all rooms.
  def default_welcome_message
    I18n.t('bigbluebutton_rails.rooms.default_welcome_msg',
           :name => self.name, :voice_number => self.voice_bridge)
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
    self.metadata.inject({}) { |result, meta|
      result["meta_#{meta.name}"] = meta.content; result
    }
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
