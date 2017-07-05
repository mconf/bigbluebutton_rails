require 'bigbluebutton_exception'

namespace :bigbluebutton_rails do
  namespace :meetings do
    desc "Checks all meetings with running==true to see if they have finished"
    task :finish => :environment do
      BigbluebuttonRails::BackgroundTasks.finish_meetings
    end

    desc "Checks for the stats of meetings that ended but have no stats yet"
    task :get_stats => :environment do
      meetings = BigbluebuttonMeeting.where(ended: true).where.not(got_stats: "yes")
      BigbluebuttonRails::BackgroundTasks.get_stats
    end
  end
end
