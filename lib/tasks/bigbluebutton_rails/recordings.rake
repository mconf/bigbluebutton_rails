namespace :bigbluebutton_rails do
  namespace :recordings do

    desc "Fetch recordings in all servers"
    task :update => :environment do
      BigbluebuttonServer.all.each do |server|
        begin
          server.fetch_recordings
          puts "[rake bigbluebutton_rails:recordings:update] List of recordings from #{server.url} updated successfully"
        rescue Exception => e
          puts "[rake bigbluebutton_rails:recordings:update] Failure fetching recordings from #{server.inspect}"
          puts e.inspect
          puts e.backtrace.join "\n"
        end
      end
    end

  end
end
