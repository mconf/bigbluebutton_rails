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
                  :moderator_password, :welcome_msg
end
