class BigbluebuttonPlaybackFormat < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :recording, :class_name => 'BigbluebuttonRecording'
  belongs_to :playback_type, :class_name => 'BigbluebuttonPlaybackType'

  delegate :name, :visible, :identifier, to: :playback_type
  alias_attribute :format_type, :identifier

  validates :recording_id, :presence => true
  validates :playback_type_id, :presence => true

  def length_in_secs
    if self.length.blank? || self.length < 0
      0
    else
      self.length * 60
    end
  end
end
