class BigbluebuttonMetadata < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true

  validates :owner, :presence => true

  validates :name,
    :presence => true,
    :format => { :with => /^[a-zA-Z]+[a-zA-Z\d_-]$/,
      :message => I18n.t('bigbluebutton_rails.metadata.errors.name_format') }
  validates :name,
    :uniqueness => { :scope => [:owner_id, :owner_id] }

  attr_accessible :owner, :name, :content
end
