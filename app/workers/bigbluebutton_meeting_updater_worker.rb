# A resque worker to get information about a meeting with `getMeetingInfo` and update
# the associated `BigbluebuttonMeeting` object. This should be called to speed up the
# update of a meeting object (usually on creates and ends).
class BigbluebuttonMeetingUpdaterWorker
  @queue = :bigbluebutton_rails

  def self.perform(room_id, wait=nil)
    Rails.logger.info "BigbluebuttonMeetingUpdaterWorker worker: waiting #{wait} for room #{room_id}"
    sleep(wait) unless wait.nil?

    room = BigbluebuttonRoom.find(room_id)
    if room.nil?
      Rails.logger.info "BigbluebuttonMeetingUpdaterWorker worker: room #{room_id} not found!"
    else
      # `fetch_meeting_info` will automatically update the meeting by
      # calling `room.update_current_meeting_record`
      room.fetch_meeting_info
    end

    # note: don't need to keep trying because there's a worker that runs periodically
    # for each meeting that still hasn't ended
  end
end
