class BigbluebuttonMetadata < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

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
  validate :exclusion_of_name_in_reserved_metadata_keys

  # metadata keys are only invalid when the metadata belongs to a room,
  # metadata that will be used in a 'create' call
  # TODO: a better solution for rails >= 3.1
  # validates :name, :exclusion => {
  #   :in => lambda do |m|
  #     if m.owner_type == "BigbluebuttonRoom"
  #       BigbluebuttonRails.metadata_invalid_keys.map(&:to_s)
  #     else
  #       []
  #     end
  #   end
  # }
  def exclusion_of_name_in_reserved_metadata_keys
    keys = if owner_type == "BigbluebuttonRoom"
             BigbluebuttonRails.metadata_invalid_keys.map(&:to_s)
           else
             []
           end
    if keys.include?(name)
      # use the same message rails would generate for :exclusion => :in
      msg = self.errors.generate_message(:name, :exclusion, {})
      errors.add(:name, msg)
    end
  end

end
