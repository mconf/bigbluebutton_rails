class BigbluebuttonRoom < ActiveRecord::Base
  belongs_to :bigbluebutton_server

  validates :bigbluebutton_server_id, :presence => true
  validates :meeting_id, :presence => true, :uniqueness => true,
    :length => { :minimum => 1, :maximum => 50 }
  validates :meeting_name, :presence => true,
    :length => { :minimum => 1, :maximum => 150 }
  validates :attendee_password, :length => { :maximum => 50 }
  validates :moderator_password, :length => { :maximum => 50 }
  validates :welcome_msg, :length => { :maximum => 250 }
end
