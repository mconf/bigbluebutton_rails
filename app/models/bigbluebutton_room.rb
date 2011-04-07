class BigbluebuttonRoom < ActiveRecord::Base
  belongs_to :server, :class_name => 'BigbluebuttonServer'
  belongs_to :owner, :polymorphic => true

  validates :server_id, :presence => true
  validates :meeting_id, :presence => true, :uniqueness => true,
    :length => { :minimum => 1, :maximum => 100 }
  validates :name, :presence => true, :uniqueness => true,
    :length => { :minimum => 1, :maximum => 150 }
  validates :attendee_password, :length => { :maximum => 50 }
  validates :moderator_password, :length => { :maximum => 50 }
  validates :welcome_msg, :length => { :maximum => 250 }

  attr_accessible :name, :server_id, :meeting_id, :attendee_password,
                  :moderator_password, :welcome_msg, :owner, :server

  # Note: these params need to be fetched before being accessed
  attr_reader :running, :participant_count, :moderator_count, :attendees,
              :has_been_forcibly_ended, :start_time, :end_time

  def fetch_meeting_info
    response = self.server.api.get_meeting_info(self.meeting_id, self.moderator_password)

    @participant_count = response[:participantCount]
    @moderator_count = response[:moderatorCount]
    @running = response[:running].downcase == "true"
    @has_been_forcibly_ended = response[:hasBeenForciblyEnded].downcase == "true"
    @start_time = response[:startTime] == "null" ?
                  nil : DateTime.parse(response[:startTime])
    @end_time = response[:endTime] == "null" ?
                nil : DateTime.parse(response[:endTime])
    @attendees = []
    response[:attendees].each do |att|
      attendee = BigbluebuttonAttendee.new
      attendee.from_hash(att)
      @attendees << attendee 
    end

    response
  end

  def fetch_is_running?
    @running = self.server.api.is_meeting_running?(self.meeting_id)
  end

end