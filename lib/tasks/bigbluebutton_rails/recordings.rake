namespace :bigbluebutton_rails do
  namespace :recordings do
    desc "Fetch recordings in all servers"
    task :update => :environment do
      BigbluebuttonRails::BackgroundTasks.update_recordings
    end
  end
end
