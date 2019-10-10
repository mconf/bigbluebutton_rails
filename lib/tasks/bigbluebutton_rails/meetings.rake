require 'bigbluebutton_exception'

namespace :bigbluebutton_rails do
  namespace :meetings do
    desc "Checks all meetings with running==true to see if they have finished"
    task :finish => :environment do
      BigbluebuttonRails::BackgroundTasks.finish_meetings
    end
 end
end
