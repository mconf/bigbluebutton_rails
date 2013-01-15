class BigbluebuttonMetadata < ActiveRecord::Base
  belongs_to :recording, :class_name => 'BigbluebuttonRecording'

  validates :recording_id, :presence => true

  validates :name, :presence => true

  attr_accessible :recording_id, :name, :content
end
