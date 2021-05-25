# A resque worker to get the list of recordings from the server and update
# the database.
# Same as "rake bigbluebutton_rails:recordings:update".
class BigbluebuttonUpdateRecordingsWorker
  @queue = :bigbluebutton_rails

  def self.perform(server_id=nil)
    Rails.logger.info "BigbluebuttonUpdateRecordingsWorker worker running"

    # TODO: configurable filter of rooms
    BigbluebuttonRails::BackgroundTasks.update_recordings_by_room

    Rails.logger.info "BigbluebuttonUpdateRecordingsWorker worker ended"
  end
end
