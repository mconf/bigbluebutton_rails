# TODO: This worker exists only because we don't have yet a way to figure out
# precisely when a getStats is ready for a meeting/room. Ideally the web conference
# server would send us a request notifying of events.

# A resque worker to call `getStats` for a meeting.
class BigbluebuttonGetStatsForMeetingWorker
  @queue = :bigbluebutton_rails

  def self.perform(meeting_id, tries_left=0)
    Rails.logger.info "BigbluebuttonGetStatsForMeetingWorker worker running"

    meeting = BigbluebuttonMeeting.find(meeting_id)
    if meeting.present?
      Rails.logger.info "BigbluebuttonGetStatsForMeetingWorker calling getStats for #{meeting.inspect}"

      if meeting.got_stats == 'yes'
        Rails.logger.info "BigbluebuttonGetStatsForMeetingWorker already have stats, aborting"
        got_it = true
      else
        got_it = meeting.fetch_and_update_stats
      end

      if tries_left > 0 && !got_it
        Rails.logger.info "BigbluebuttonGetStatsForMeetingWorker scheduling a worker to try again more #{tries_left - 1}x"
        Resque.enqueue_in(5.minute, ::BigbluebuttonGetStatsForMeetingWorker, meeting.id, tries_left - 1)
      end
    end
  end
end
