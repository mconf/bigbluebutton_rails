class BigbluebuttonPlaybackFormat < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :recording, :class_name => 'BigbluebuttonRecording'
  belongs_to :playback_type, :class_name => 'BigbluebuttonPlaybackType'

  delegate :name, :visible, :identifier, to: :playback_type
  alias_attribute :format_type, :identifier

  validates :recording_id, :presence => true
  validates :playback_type_id, :presence => true
end
