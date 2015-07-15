require 'bigbluebutton_api'

class BigbluebuttonServerConfig < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :server, class_name: 'BigbluebuttonServer'
  validates :server_id, presence: true

  serialize :available_layouts, Array

  # This is called when the config.xml is requested to update the info that is
  # being stored locally. Currently the only info stored is about the available
  # layouts. It is also called without the config_xml parameter when we are
  # forcing the update (via Resque task for example).
  def update_config(config_xml = nil)
    begin
      config_xml = self.server.api.get_default_config_xml if config_xml.nil?
      layouts = self.server.api.get_available_layouts(config_xml)
      self.update_attributes(available_layouts: layouts) unless layouts.nil?
    rescue BigBlueButton::BigBlueButtonException
      Rails.logger.error "Could not fetch configurations for the server #{self.server.id}. The URL probably incorrect."
    end
  end

  def available_layouts_names
    # Translate the keys that come from server.available_layouts.
    # If it's not a valid key (e.g. it's already a name) keep it as it is.
    available_layouts.map { |layout|
      I18n.t(layout, default: layout)
    }
  end

  def available_layouts_with_names
    available_layouts_names.zip(available_layouts)
  end
end
