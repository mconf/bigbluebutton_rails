# A resque worker to get the list of recordings from the server and update
# the database.
# Same as "rake bigbluebutton_rails:recordings:update".
class BigbluebuttonUpdateRecordingsWorker
  @queue = :bigbluebutton_rails

  def self.perform(server_id=nil)
    Rails.logger.info "BigbluebuttonUpdateRecordingsWorker worker running"

    query = BigbluebuttonRails.configuration.rooms_for_full_recording_sync.call
    all_room_servers = true
    BigbluebuttonRails::BackgroundTasks.update_recordings_by_room(query, all_room_servers)

    Rails.logger.info "BigbluebuttonUpdateRecordingsWorker worker ended"
  end
end
