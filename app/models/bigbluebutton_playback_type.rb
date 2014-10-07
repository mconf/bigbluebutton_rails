class BigbluebuttonPlaybackType < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  validates :identifier, :presence => true

  validates :i18n_key, :presence => true

  has_many :playback_formats,
           :class_name => 'BigbluebuttonPlaybackFormat',
           :foreign_key => 'playback_type_id',
           :dependent => :destroy

end
