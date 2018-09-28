class BigbluebuttonRailsTo240 < ActiveRecord::Migration
  def self.up
    add_column :bigbluebutton_meetings, :description, :string
    add_column :bigbluebutton_meetings, :title, :string, limit: 80

    BigbluebuttonMeeting.find_each do |meeting|
      if !meeting.name.blank?
        meeting.update_attributes(title: meeting.name)
      end

      if meeting.name.recorded?
        meeting.update_attributes(description: meeting.recording.description)
      end
    end

    remove_column :bigbluebutton_meetings, :name
    remove_column :bigbluebutton_recordings, :description
  end

  def self.down
  end

end
