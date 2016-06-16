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
        if !e.key.blank? && e.key == 'notFound'
          Rails.logger.info "BigbluebuttonMeetingUpdater worker: detected that a meeting ended in the room: #{room.inspect}"
          room.finish_meetings
        else
          raise e
        end
      end
    end
    Rails.logger.flush

    # note: don't need to keep trying because there's a worker that runs periodically
    # for each meeting that still hasn't ended
  end
end
