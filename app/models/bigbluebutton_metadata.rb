class BigbluebuttonMetadata < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true, :inverse_of => :metadata

  validates :owner_id, :presence => true
  validates :owner_type, :presence => true

  validates :name, :presence => true
  validates :name, :format => {
    :with => /^[a-zA-Z]+[a-zA-Z\d-]*$/,
    :message => I18n.t('bigbluebutton_rails.metadata.errors.name_format')
  }
  validates :name,
    :uniqueness => { :scope => [:owner_id, :owner_type] }
  validates :name, :exclusion => {
    :in => lambda do |m|
      # metadata keys are only invalid when the metadata belongs to a room,
      # metadata that will be used in a 'create' call
      if m.owner_type == "BigbluebuttonRoom"
        BigbluebuttonRails.metadata_invalid_keys.map(&:to_s)
      else
        []
      end
    end
  }

  attr_accessible :name, :content
end
