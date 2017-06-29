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

    # Gets additional informations about an ended meeting, like it's duration and a list
    # of participants with join and leave timestamp
    def self.get_stats
      BigbluebuttonMeeting.where(got_stats: nil, ended: true)
        .where("create_time > ?", (DateTime.now.utc - 1.day).strftime('%Q').to_i)
        .find_each do |meeting|

        Rails.logger.info "BackgroundTasks: Checking if the meeting has getStats content: #{meeting.inspect}"
        meeting.fetch_and_update_stats(meeting)
      end
    end

    # Updates the recordings for all servers if `server_id` is nil or or for the
    # server with id `server_id`.
    def self.update_recordings(server_id=nil)
      BigbluebuttonServer.find_each do |server|
        begin
          if server_id.nil? || server_id == server.id
            server.fetch_recordings(nil, true)
            Rails.logger.info "BackgroundTasks: List of recordings from #{server.url} updated successfully"
          end
        rescue Exception => e
          Rails.logger.info "BackgroundTasks: Failure fetching recordings from #{server.inspect}"
          Rails.logger.info "BackgroundTasks: #{e.inspect}"
          Rails.logger.info "BackgroundTasks: #{e.backtrace.join("\n")}"
        end
      end
    end

  end

end
