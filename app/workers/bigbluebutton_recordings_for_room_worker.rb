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
    return if BigbluebuttonRails.configuration.use_webhooks

    Rails.logger.info "BigbluebuttonRecordingsForRoomWorker worker running"

    room = BigbluebuttonRoom.find(room_id)
    if room.present?
      Rails.logger.info "BigbluebuttonRecordingsForRoomWorker getting recordings for #{room.inspect}"
      room.fetch_recordings( state: BigbluebuttonRecording::STATES.values)

      if tries_left > 0
        Resque.enqueue_in(5.minutes, ::BigbluebuttonRecordingsForRoomWorker, room_id, tries_left - 1)
      end
    end
  end
end
