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

    # Updates the recordings for all servers if `server_id` is nil or for the
    # server with id `server_id`.
    def self.update_recordings_by_server(server=nil)
      Rails.logger.info "BackgroundTasks: Starting the update of recordings by server server=#{server&.url};#{server&.secret}"

      if server.nil?
        BigbluebuttonServer.find_each do |server|
          update_recordings_for_server(server)
        end
      else
        update_recordings_for_server(server)
      end

      Rails.logger.info "BackgroundTasks: Ended the update of recordings by server server=#{server&.url};#{server&.secret}"
    end

    # Updates the recordings for all rooms if `query` is nil or will use `query` to fetch the rooms
    # that should be updated.
    def self.update_recordings_by_room(query=nil)
      query_s = "query=\"#{query&.to_sql}\""
      Rails.logger.info "BackgroundTasks: Starting the update of recordings by room #{query_s}"

      query = BigbluebuttonRoom if query.blank?
      query.find_each do |room|
        update_recordings_for_room(room)
      end

      Rails.logger.info "BackgroundTasks: Ended the update of recordings by room #{query_s}"
    end

    def self.update_recordings_for_server(server)
      begin
        server.fetch_recordings
        Rails.logger.info "BackgroundTasks: List of recordings for #{server.url} updated successfully"
      rescue StandardError => e
        Rails.logger.info "BackgroundTasks: Failure fetching recordings from #{server.url} #{e.inspect}"
        Rails.logger.debug "BackgroundTasks: #{e.backtrace.join("\n")}"
      end
    end

    def self.update_recordings_for_room(room)
      begin
        room.fetch_recordings
        Rails.logger.info "BackgroundTasks: List of recordings for #{room.meetingid} updated successfully"
      rescue StandardError => e
        Rails.logger.info "BackgroundTasks: Failure fetching recordings for room #{room.meetingid} #{e.inspect}"
        Rails.logger.debug "BackgroundTasks: #{e.backtrace.join("\n")}"
      end
    end
  end
end
