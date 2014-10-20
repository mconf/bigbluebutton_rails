module BigbluebuttonRails

  # Helper methods to execute tasks that run in resque and rake.
  class BackgroundTasks

    def self.finish_meetings
      BigbluebuttonMeeting.where(running: true).find_each do |meeting|
        Rails.logger.info "BackgroundTasks: Checking if the meeting has ended: #{meeting.inspect}"
        if meeting.room and !meeting.room.fetch_is_running?
          Rails.logger.info "BackgroundTasks: Setting meeting as ended: #{meeting.inspect}"
          meeting.update_attributes(running: false)
        end
      end
    end

    def self.update_recordings
      BigbluebuttonServer.find_each do |server|
        begin
          server.fetch_recordings
          Rails.logger.info "BackgroundTasks: List of recordings from #{server.url} updated successfully"
        rescue Exception => e
          Rails.logger.info "BackgroundTasks: Failure fetching recordings from #{server.inspect}"
          Rails.logger.info "BackgroundTasks: #{e.inspect}"
          Rails.logger.info "BackgroundTasks: #{e.backtrace.join("\n")}"
        end
      end
    end

  end

end
