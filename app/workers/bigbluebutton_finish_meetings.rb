# A resque worker to check for meetings that already finished and mark
# them as finished.
# Same as "rake bigbluebutton_rails:meetings:finish".
class BigbluebuttonFinishMeetings
  @queue = :bigbluebutton_rails

  def self.perform
    Rails.logger.info "BigbluebuttonFinishMeetings worker running"
    BigbluebuttonRails::BackgroundTasks.finish_meetings
  end
end
