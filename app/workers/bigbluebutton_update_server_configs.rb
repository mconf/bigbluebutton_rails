# A resque worker to get the server configs from time to time (information such
# as available layouts are updated).
class BigbluebuttonUpdateServerConfigs
  @queue = :bigbluebutton_rails

  def self.perform
    Rails.logger.info "BigbluebuttonUpdateServerConfigs worker running"
    BigbluebuttonServer.find_each do |server|
      Rails.logger.info "BigbluebuttonUpdateServerConfigs updating configs for #{server.inspect}"

      # update configs
      server.update_config

      # update API version
      server.update_attributes(version: server.set_api_version_from_server)
    end
  end
end
