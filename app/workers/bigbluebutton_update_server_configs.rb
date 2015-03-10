# A resque worker to get the server configs from time to time (information such
# as available layouts are updated).
class BigbluebuttonUpdateServerConfigs
  @queue = :bigbluebutton_rails

  def self.perform
    BigbluebuttonServer.all.each do |server|
      server.config.update_config
    end
  end
end
