class BigbluebuttonPlaybackType < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  validates :identifier, :presence => true

  has_many :playback_formats,
           :class_name => 'BigbluebuttonPlaybackFormat',
           :foreign_key => 'playback_type_id',
           :dependent => :destroy

  def name
    I18n.t("bigbluebutton_rails.playback_types.#{self.identifier}")
  end
end
