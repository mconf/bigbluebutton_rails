class BigbluebuttonPlaybackType < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  validates :identifier, :presence => true

  has_many :playback_formats,
           :class_name => 'BigbluebuttonPlaybackFormat',
           :foreign_key => 'playback_type_id',
           :dependent => :nullify

  # Ensure there will be 0 or 1 (no more) records with default=true.
  # Setting a record with default=true will automatically set all others to default=false.
  before_save :ensure_default_uniqueness
  def ensure_default_uniqueness
    if default_changed? && default?
      self.class.where('id != ?', self.id).update_all(default: false)
    end
  end

  def name
    default = self.identifier.gsub("_", " ").titleize
    I18n.t("bigbluebutton_rails.playback_types.#{self.identifier}.name", default: default)
  end

  def description
    default = self.identifier.gsub("_", " ").titleize
    I18n.t("bigbluebutton_rails.playback_types.#{self.identifier}.tip", default: default)
  end
end
