require 'active_support/secure_random'

class BigbluebuttonRoom < ActiveRecord::Base
  belongs_to :server, :class_name => 'BigbluebuttonServer'
  belongs_to :owner, :polymorphic => true

  validates :server_id, :presence => true
  validates :meeting_id, :presence => true, :uniqueness => true,
    :length => { :minimum => 1, :maximum => 100 }
  validates :name, :presence => true, :uniqueness => true,
    :length => { :minimum => 1, :maximum => 150 }
  validates :welcome_msg, :length => { :maximum => 250 }
  validates :private, :inclusion => { :in => [true, false] }
  validates :randomize_meetingid, :inclusion => { :in => [true, false] }

  # Passwords are 16 character strings
  # See http://groups.google.com/group/bigbluebutton-dev/browse_thread/thread/9be5aae1648bcab?pli=1
  validates :attendee_password, :length => { :maximum => 16 }
  validates :moderator_password, :length => { :maximum => 16 }

  attr_accessible :name, :server_id, :meeting_id, :attendee_password, :moderator_password,
                  :welcome_msg, :owner, :server, :private, :logout_url, :dial_number,
                  :voice_bridge, :max_participants, :owner_id, :owner_type, :randomize_meetingid

  # Note: these params need to be fetched from the server before being accessed
  attr_accessor :running, :participant_count, :moderator_count, :attendees,
                :has_been_forcibly_ended, :start_time, :end_time

  after_initialize :init

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
  # Triggers API call: <tt>get_meeting_info</tt>.
  def fetch_meeting_info
    response = self.server.api.get_meeting_info(self.meeting_id, self.moderator_password)

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
  # Triggers API call: <tt>is_meeting_running</tt>.
  def fetch_is_running?
    @running = self.server.api.is_meeting_running?(self.meeting_id)
  end

  # Sends a call to the BBB server to end the meeting.
  #
  # Triggers API call: <tt>end_meeting</tt>.
  def send_end
    self.server.api.end_meeting(self.meeting_id, self.moderator_password)
  end

  # Sends a call to the BBB server to create the meeting.
  #
  # With the response, updates the following attributes:
  # * <tt>attendee_password</tt>
  # * <tt>moderator_password</tt>
  #
  # Triggers API call: <tt>create_meeting</tt>.
  def send_create

    unless self.randomize_meetingid
      response = do_create_meeting

    # create a new random meetingid everytime create fails with "duplicateWarning"
    else
      self.meeting_id = random_meetingid

      count = 0
      try_again = true
      while try_again and count < 10
        response = do_create_meeting

        count += 1
        try_again = false
        unless response.nil?
          if response[:returncode] && response[:messageKey] == "duplicateWarning"
            self.meeting_id = random_meetingid
            try_again = true
          end
        end

      end
    end

    unless response.nil?
      self.attendee_password = response[:attendeePW]
      self.moderator_password = response[:moderatorPW]
      self.save
    end

    response
  end

  # Returns the URL to join this room.
  # username:: Name of the user
  # role:: Role of the user in this room. Can be <tt>[:moderator, :attendee]</tt>
  #
  # Uses the API but does not require a request to the server.
  def join_url(username, role)
    if role == :moderator
      self.server.api.join_meeting_url(self.meeting_id, username, self.moderator_password)
    else
      self.server.api.join_meeting_url(self.meeting_id, username, self.attendee_password)
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

  protected

  def init
    self[:meeting_id] ||= random_meetingid

    # fetched attributes
    @participant_count = 0
    @moderator_count = 0
    @running = false
    @has_been_forcibly_ended = false
    @start_time = nil
    @end_time = nil
    @attendees = []
  end

  def random_meetingid
    #ActiveSupport::SecureRandom.hex(16)
    # TODO temporarily using the name to get a friendlier meeting_id
    if self[:name].blank?
      ActiveSupport::SecureRandom.hex(8)
    else
      self[:name] + '-' + ActiveSupport::SecureRandom.random_number(9999).to_s
    end
  end

  def do_create_meeting
    self.server.api.create_meeting(self.name, self.meeting_id, self.moderator_password,
                                   self.attendee_password, self.welcome_msg, self.dial_number,
                                   self.logout_url, self.max_participants, self.voice_bridge)
  end

end
