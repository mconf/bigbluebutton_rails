# A resque worker to check for meetings that already finished and mark
# them as finished.
# Same as "rake bigbluebutton_rails:meetings:finish".
class BigbluebuttonFinishMeetingsWorker
  @queue = :bigbluebutton_rails

  def self.perform
    Rails.logger.info "BigbluebuttonFinishMeetingsWorker worker running"
    BigbluebuttonRails::BackgroundTasks.finish_meetings
  end
end
