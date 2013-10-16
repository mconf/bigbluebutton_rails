# A resque worker to get information about a meeting with `getMeetingInfo` and update
# the associated `BigbluebuttonMeeting` object. This should be triggered whenever a,
# meeting is created, ended, or when a user joins.
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
        room.fetch_meeting_info
      rescue BigBlueButton::BigBlueButtonException => e
        Rails.logger.info "BigbluebuttonMeetingUpdater worker: getMeetingInfo generated an error (usually means that the meeting doesn't exist): #{e}"

        # an error usually means that no meeting was found, so it is not running anymore
        room.finish_meetings
      else
        Rails.logger.info "BigbluebuttonMeetingUpdater worker: updating the meetings for the room #{room_id}"
        room.update_current_meeting
      end
    end
    Rails.logger.flush

    # TODO: if the meeting is not found (or is not running), try again a few more times?
  end
end
