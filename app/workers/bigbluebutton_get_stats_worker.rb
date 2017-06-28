# A resque worker to check for meeting's data like time it started and ended
# and the list of participants with join and leave timestamp for each of them
# Same as "rake bigbluebutton_rails:meetings:get_stats".
class BigbluebuttonGetStatsWorker
  @queue = :bigbluebutton_rails

  def self.perform
    Rails.logger.info "BigbluebuttonGetStatsWorker worker running"
    BigbluebuttonRails::BackgroundTasks.get_stats
  end
end
