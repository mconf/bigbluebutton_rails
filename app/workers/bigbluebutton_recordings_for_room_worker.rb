# TODO: This worker exists only because we don't have yet a way to figure out
# precisely when a recording is done processing. Ideally the web conference
# server would send us a request notifying that the recording is ready.
# For now, this worker is used to get all recordings of a room after a meeting
# is ended in the room. It keeps trying a few times even if a recording was
# already found, which is important in case there are multiple playback formats
# that are processed individually (e.g. the first time the recording is found it
# might have only one of the formats done).

# A resque worker to get the recordings of a room.
class BigbluebuttonRecordingsForRoomWorker
  @queue = :bigbluebutton_rails

  def self.perform(room_id, tries_left=0)
    return if tries_left <= 0

    Rails.logger.info "BigbluebuttonRecordingsForRoomWorker worker running " \
                      "room_id=#{room_id} tries_left=#{tries_left}"

    room = BigbluebuttonRoom.find(room_id)
    if room.present?
      Rails.logger.info "BigbluebuttonRecordingsForRoomWorker getting recordings for meetingid=#{room.meetingid}"

      room.fetch_recordings

      intervals = BigbluebuttonRails.configuration.recording_sync_for_room_intervals
      idx = intervals.length - tries_left
      wait = intervals[idx]
      wait = intervals[intervals.length - 1] if wait.nil?

      Resque.enqueue_in(wait, ::BigbluebuttonRecordingsForRoomWorker, room_id, tries_left - 1)
    end

    Rails.logger.info "BigbluebuttonRecordingsForRoomWorker worker ended " \
                      "room_id=#{room_id} tries_left=#{tries_left}"
  end
end
