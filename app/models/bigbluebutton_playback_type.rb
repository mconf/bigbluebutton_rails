class BigbluebuttonPlaybackType < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  validates :identifier, :presence => true

  has_many :playback_formats,
           :class_name => 'BigbluebuttonPlaybackFormat',
           :foreign_key => 'playback_type_id',
           :dependent => :nullify

  def name
    default = self.identifier.gsub("_", " ").titleize
    I18n.t("bigbluebutton_rails.playback_types.#{self.identifier}", default: default)
  end
end
