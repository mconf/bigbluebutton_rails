# A resque worker to get the list of recordings from the server and update
# the database.
# Same as "rake bigbluebutton_rails:recordings:update".
class BigbluebuttonUpdateRecordingsWorker
  @queue = :bigbluebutton_rails

  def self.perform(server_id=nil)
    Rails.logger.info "BigbluebuttonUpdateRecordingsWorker worker running"

    query = BigbluebuttonRails.configuration.rooms_for_full_recording_sync.call
    BigbluebuttonRails::BackgroundTasks.update_recordings_by_room(query)

    Rails.logger.info "BigbluebuttonUpdateRecordingsWorker worker ended"
  end
end
