# A resque worker to get the list of recordings from the server and update
# the database.
# Same as "rake bigbluebutton_rails:recordings:update".
class BigbluebuttonUpdateRecordings
  @queue = :bigbluebutton_rails

  def self.perform
    Rails.logger.info "BigbluebuttonUpdateRecordings worker running"
    BigbluebuttonRails::BackgroundTasks.update_recordings
  end
end
