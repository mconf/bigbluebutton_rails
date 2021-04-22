module BigbluebuttonRails

  # Helper methods to execute tasks that run in resque and rake.
  class BackgroundTasks

    # For each meeting that hasn't ended yet, call `getMeetingInfo` and update
    # the meeting attributes or end it.
    def self.finish_meetings
      BigbluebuttonMeeting.where(ended: false).find_each do |meeting|
        Rails.logger.info "BackgroundTasks: Checking if the meeting has ended: #{meeting.inspect}"
        room = meeting.room
        if room.present? #and !meeting.room.fetch_is_running?
          # `fetch_meeting_info` will automatically update the meeting by
          # calling `room.update_current_meeting_record`
          room.fetch_meeting_info
        end
      end
    end

    # Updates the recordings for all servers if `server_id` is nil or or for the
    # server with id `server_id`.
    def self.update_recordings(server_id=nil)
      Rails.logger.info "BackgroundTasks: Starting the update of recordings for all servers"
      BigbluebuttonServer.find_each do |server|
        begin
          if server_id.nil? || server_id == server.id
            server.fetch_recordings(nil, true)
            Rails.logger.info "BackgroundTasks: List of recordings from #{server.url} updated successfully"
          end
        rescue StandardError => e
          Rails.logger.info "BackgroundTasks: Failure fetching recordings from #{server.inspect}"
          Rails.logger.info "BackgroundTasks: #{e.inspect}"
          Rails.logger.info "BackgroundTasks: #{e.backtrace.join("\n")}"
        end
      end
      Rails.logger.info "BackgroundTasks: Ended the update of recordings for all servers"
    end
  end
end
