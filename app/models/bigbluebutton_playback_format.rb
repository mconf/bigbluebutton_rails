class BigbluebuttonPlaybackFormat < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :recording, :class_name => 'BigbluebuttonRecording'

  validates :recording_id, :presence => true

  validates :format_type, :presence => true
end
