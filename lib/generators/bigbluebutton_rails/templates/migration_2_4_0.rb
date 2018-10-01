class BigbluebuttonRailsTo240 < ActiveRecord::Migration
  def self.up
    add_column :bigbluebutton_meetings, :title, :string, limit: 80

    BigbluebuttonMeeting.find_each do |meeting|
      if meeting.name.recorded?
        meeting.update_attributes(title: meeting.recording.description)
      end
    end

    remove_column :bigbluebutton_recordings, :description
  end

  def self.down
  end
end
