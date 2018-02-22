class BigbluebuttonPlaybackFormat < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :recording, :class_name => 'BigbluebuttonRecording'
  belongs_to :playback_type, :class_name => 'BigbluebuttonPlaybackType'

  delegate :name, :identifier, :visible, :visible?, :default, :default?,
           :description, :downloadable, :downloadable?,
           to: :playback_type, allow_nil: true
  alias_attribute :format_type, :identifier

  validates :recording_id, :presence => true

  scope :ordered, -> {
    default = joins(:playback_type).where("bigbluebutton_playback_types.default = ?", true)
    if default.pluck(:id).empty?
      others = all
    else
      others = where("id NOT IN (?)", default.pluck(:id))
    end
    default.concat others
  }

  def length_in_secs
    if self.length.blank? || self.length < 0
      0
    else
      self.length * 60
    end
  end
end
