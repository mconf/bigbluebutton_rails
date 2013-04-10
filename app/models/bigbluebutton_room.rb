class BigbluebuttonRoom < ActiveRecord::Base
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

  accepts_nested_attributes_for :metadata,
    :allow_destroy => true,
    :reject_if => :all_blank

  validates :meetingid, :presence => true, :uniqueness => true,
    :length => { :minimum => 1, :maximum => 100 }
  validates :name, :presence => true, :uniqueness => true,
    :length => { :minimum => 1, :maximum => 150 }
  validates :welcome_msg, :length => { :maximum => 250 }
  validates :private, :inclusion => { :in => [true, false] }
  validates :voice_bridge, :presence => true, :uniqueness => true
  validates :record, :inclusion => { :in => [true, false] }

  validates :duration,
    :presence => true,
    :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }

  validates :param,
            :presence => true,
            :uniqueness => true,
            :length => { :minimum => 3 },
            :format => { :with => /^[a-zA-Z\d_]+[a-zA-Z\d_-]*[a-zA-Z\d_]+$/,
                         :message => I18n.t('bigbluebutton_rails.rooms.errors.param_format') }

  validates :uniqueid,
            :presence => true, # not really needed, will be created before_validation if nil
            :uniqueness => true,
            :length => { :minimum => 16 }

  # Passwords are 16 character strings
  # See http://groups.google.com/group/bigbluebutton-dev/browse_thread/thread/9be5aae1648bcab?pli=1
  validates :attendee_password, :length => { :maximum => 16 }
  validates :moderator_password, :length => { :maximum => 16 }

  validates :attendee_password, :presence => true, :if => :private?
  validates :moderator_password, :presence => true, :if => :private?

  attr_accessible :name, :server_id, :meetingid, :attendee_password, :moderator_password,
                  :welcome_msg, :owner, :server, :private, :logout_url, :dial_number,
                  :voice_bridge, :max_participants, :owner_id, :owner_type,
                  :external, :param, :record, :duration, :metadata_attributes

  # Note: these params need to be fetched from the server before being accessed
  attr_accessor :running, :participant_count, :moderator_count, :attendees,
                :has_been_forcibly_ended, :start_time, :end_time

  after_initialize :init
  before_validation :set_param
  before_validation :generate_uniqueid

  # the full logout_url used when logout_url is a relative path
  attr_accessor :full_logout_url

  # HTTP headers that will be passed to the BigBlueButtonApi object to send
  # in all GET/POST requests to a webconf server.
  # Currently used to send the client's IP to the load balancer.
  attr_accessor :request_headers

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

    response = self.server.api.get_meeting_info(self.meetingid, self.moderator_password)

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
    self.server.api.end_meeting(self.meetingid, self.moderator_password)
  end

  # Sends a call to the BBB server to create the meeting.
  # 'username' is the name of the user that is creating the meeting.
  # 'userid' is the id of the user that is creating the meeting.
  #
  # Will trigger 'select_server' to select a server where the meeting
  # will be created. If a server is selected, the model is saved.
  #
  # With the response, updates the following attributes:
  # * <tt>attendee_password</tt>
  # * <tt>moderator_password</tt>
  #
  # Triggers API call: <tt>create</tt>.
  def send_create(username=nil, userid=nil)
    # updates the server whenever a meeting will be created and guarantees it has a meetingid
    self.server = select_server
    self.meetingid = unique_meetingid() if self.meetingid.nil?
    self.save unless self.new_record?
    require_server

    response = do_create_meeting(username, userid)
    unless response.nil?
      self.attendee_password = response[:attendeePW]
      self.moderator_password = response[:moderatorPW]
      self.save unless self.new_record?
    end

    response
  end

  # Returns the URL to join this room.
  # username:: Name of the user
  # role:: Role of the user in this room. Can be <tt>[:moderator, :attendee]</tt>
  # password:: Password to be use (in case role == nil)
  #
  # Uses the API but does not require a request to the server.
  def join_url(username, role, password=nil)
    require_server

    case role
    when :moderator
      self.server.api.join_meeting_url(self.meetingid, username, self.moderator_password)
    when :attendee
      self.server.api.join_meeting_url(self.meetingid, username, self.attendee_password)
    else
      self.server.api.join_meeting_url(self.meetingid, username, password)
    end
  end


  # Returns the role of the user based on the password given.
  # The return value can be <tt>:moderator</tt>, <tt>:attendee</tt>, or
  # nil if the password given does not match any of the room passwords.
  # params:: Hash with a key :password
  def user_role(params)
    role = nil
    if params.has_key?(:password)
      if self.moderator_password == params[:password]
        role = :moderator
      elsif self.attendee_password == params[:password]
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
  def create_meeting(username, userid=nil, request=nil)
    fetch_is_running?
    unless is_running?
      add_domain_to_logout_url(request.protocol, request.host_with_port) unless request.nil?
      send_create(username, userid)
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

  protected

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
    generate_uniqueid()

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

  def do_create_meeting(username=nil, userid=nil)
    opts = {
      :record => self.record,
      :duration => self.duration,
      :moderatorPW => self.moderator_password,
      :attendeePW => self.attendee_password,
      :welcome => self.welcome_msg.blank? ? default_welcome_message : self.welcome_msg,
      :dialNumber => self.dial_number,
      :logoutURL => self.full_logout_url || self.logout_url,
      :maxParticipants => self.max_participants,
      :voiceBridge => self.voice_bridge
    }.merge(self.get_metadata_for_create)

    # Add a globally unique identifier to match recordings when fetched
    opts.merge!({ "meta_#{BigbluebuttonRails.metadata_room_id}" => self.uniqueid })

    # Add information about the user that is creating the meeting (if any)
    opts.merge!({ "meta_#{BigbluebuttonRails.metadata_user_id}" => userid }) unless userid.nil?
    opts.merge!({ "meta_#{BigbluebuttonRails.metadata_user_name}" => username }) unless username.nil?

    self.server.api.request_headers = @request_headers # we need the client's IP
    self.server.api.create_meeting(self.name, self.meetingid, opts)
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

  def get_metadata_for_create
    self.metadata.inject({}) { |result, meta|
      result["meta_#{meta.name}"] = meta.content; result
    }
  end

  def generate_uniqueid
    # Automatically generated id that should be unique to identify this object
    # in case more that one bigbluebutton_rails application is using the same
    # web conference server.
    self[:uniqueid] ||= "#{SecureRandom.hex(16)}-#{Time.now.to_i}"
  end

end
