# A resque worker to get information about a meeting with `getMeetingInfo` and update
# the associated `BigbluebuttonMeeting` object. This should be called to speed up the
# update of a meeting object (usually on creates and ends).
class BigbluebuttonMeetingUpdater
  @queue = :bigbluebutton_rails

  def self.perform(room_id, wait=nil)
    Rails.logger.info "BigbluebuttonMeetingUpdater worker: waiting #{wait} for room #{room_id}"
    sleep(wait) unless wait.nil?

    room = BigbluebuttonRoom.find(room_id)
    if room.nil?
      Rails.logger.info "BigbluebuttonMeetingUpdater worker: room #{room_id} not found!"
    else
      begin
        # `fetch_meeting_info` will automatically update the meeting by
        # calling `room.update_current_meeting_record`
        room.fetch_meeting_info
      rescue BigBlueButton::BigBlueButtonException => e
        Rails.logger.info "BigbluebuttonMeetingUpdater worker: getMeetingInfo generated an error (usually means that the meeting doesn't exist): #{e}"

        # TODO: get only the specific meetingID notFound exception

        # an error usually means that no meeting was found, so it is not running anymore
        room.finish_meetings
      end
    end
    Rails.logger.flush

    # note: don't need to keep trying because there's a worker that runs periodically
    # for each meeting that still hasn't ended
  end
end
