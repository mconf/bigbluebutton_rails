require 'bigbluebutton_exception'

namespace :bigbluebutton_rails do
  namespace :meetings do
    desc "Checks all meetings with running==true to see if they have finished"
    task :finish => :environment do
      BigbluebuttonRails::BackgroundTasks.finish_meetings
    end
    desc "Checks for the stats of meetings with got_stats=='not_yet' to see if they have additional info"
    task :get_stats => :environment do
      BigbluebuttonRails::BackgroundTasks.get_stats
    end
  end
end
