class BigbluebuttonAttendee < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :meeting, :class_name => 'BigbluebuttonMeeting',
             :foreign_key => :bigbluebutton_meeting_id

  validates :bigbluebutton_meeting_id, :presence => true

  # TODO: no role on getStats yet, but it exists on getMeetings
  attr_accessor :role

  def duration
    self.left_time - self.join_time
  end

  def from_hash(hash)
    self.user_id = hash[:userID].to_s
    self.user_name = hash[:fullName].to_s
    self.role = hash[:role].to_s.downcase == "moderator" ? :moderator : :attendee
  end
end
