class BigbluebuttonRoom < ActiveRecord::Base
  belongs_to :server, :class_name => 'BigbluebuttonServer'
  belongs_to :owner, :polymorphic => true

  validates :server_id, :presence => true
  validates :meeting_id, :presence => true, :uniqueness => true,
    :length => { :minimum => 1, :maximum => 50 }
  validates :meeting_name, :presence => true,
    :length => { :minimum => 1, :maximum => 150 }
  validates :attendee_password, :length => { :maximum => 50 }
  validates :moderator_password, :length => { :maximum => 50 }
  validates :welcome_msg, :length => { :maximum => 250 }
end
