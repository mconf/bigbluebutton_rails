namespace :bigbluebutton_rails do
  namespace :recordings do

    desc "Fetch recordings in all servers"
    task :update => :environment do
      BigbluebuttonServer.all.each do |server|
        begin
          server.fetch_recordings
        rescue Exception => e
          puts "Failure fetching recordings from #{server.inspect}"
          puts e.inspect
          puts e.backtrace.join "\n"
        end
      end
    end

  end
end
