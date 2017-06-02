class BigbluebuttonAttendees < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :meeting, :class_name => 'BigbluebuttonMeeting'

  validates :bigbluebutton_meeting_id, :presence => true

  def time_attending?
    attending = self.left_time - self.join_time
  end
end
