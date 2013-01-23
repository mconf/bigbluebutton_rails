class BigbluebuttonMetadata < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true, :inverse_of => :metadata

  validates :owner_id, :presence => true
  validates :owner_type, :presence => true

  validates :name,
    :presence => true,
    :format => { :with => /^[a-zA-Z]+[a-zA-Z\d_-]*$/,
      :message => I18n.t('bigbluebutton_rails.metadata.errors.name_format') }

  validates :name,
    :uniqueness => { :scope => [:owner_id, :owner_type] }

  attr_accessible :name, :content
end
