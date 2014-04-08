require 'bigbluebutton_exception'

namespace :bigbluebutton_rails do
  namespace :meetings do

    desc "Checks all meetings with running==true to see if they have finished"
    task :finish => :environment do
      BigbluebuttonMeeting.where(:running => true).all.each do |meeting|
        begin
          puts "[rake bigbluebutton_rails:meetings:finish] Getting meeting info for: #{meeting.inspect}"
          meeting.room.fetch_meeting_info
        rescue BigBlueButton::BigBlueButtonException => e

          # it will fail with an exception if the meeting ended because the meetingID is not found
          puts "[rake bigbluebutton_rails:meetings:finish] Setting meeting as not running: #{meeting.inspect}"
          meeting.update_attributes(:running => false)
        end
      end
    end

  end
end
