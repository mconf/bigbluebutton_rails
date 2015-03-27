namespace :bigbluebutton_rails do
  namespace :server_configs do
    desc "Fetch server configs for all servers"
    task :update => :environment do
      BigbluebuttonServer.all.each do |s|
        s.update_config
      end
    end
  end
end
