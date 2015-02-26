require 'bigbluebutton_api'

class BigbluebuttonServerConfig < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :server, class_name: 'BigbluebuttonServer'
  validates :server_id, presence: true

  def get_available_layouts
    if self.available_layouts.nil? || self.available_layouts.blank?
      # Locally we store it as a comma-separated string.
      layouts = self.server.api.get_available_layouts
      self.available_layouts = layouts.join(',') unless layouts.nil?
    end
    # We return it as an array.
    unless self.available_layouts.nil?
      self.available_layouts.split(',')
    else
      nil
    end
  end

  # This is called when the config.xml is requested to update the info that is
  # being stored locally. Currently the only info stored is about the available
  # layouts.
  def update_config(config_xml)
    layouts = self.server.api.get_available_layouts(config_xml)
    self.available_layouts = layouts.join(',') unless layouts.nil?
  end
end
