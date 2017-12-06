# Get the stats for meetings that have no stats yet and are recent.
# Used as a fallback just in case there are meetings without stats because of
# enexpected errors during the standard `getStats` calls.
# Same as "rake bigbluebutton_rails:meetings:get_stats" but for a limited number
# of meetings.
class BigbluebuttonGetStatsForRecentWorker
  @queue = :bigbluebutton_rails

  def self.perform
    Rails.logger.info "BigbluebuttonGetStatsForRecentWorker worker running"

    # only meetings for which we tried to get stats before but failed for some reason
    # also, only recent meetings (past week)
    # note: just `where.not(got_stats: 'yes')` doesn't work!
    meetings = BigbluebuttonMeeting
               .where(ended: true).where("got_stats != 'yes' OR got_stats IS NULL")
               .where("create_time > ?", (DateTime.now.utc - 7.days).strftime('%Q').to_i)
    BigbluebuttonRails::BackgroundTasks.get_stats(meetings)
  end
end
