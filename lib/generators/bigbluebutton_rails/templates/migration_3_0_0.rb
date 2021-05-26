class BigbluebuttonRailsTo300 < ActiveRecord::Migration
  def self.up
    rename_column :bigbluebutton_rooms, :param, :slug
    rename_column :bigbluebutton_servers, :param, :slug
    add_column :bigbluebutton_recordings, :state, :string
    add_column :bigbluebutton_meetings, :title, :string, limit: 80

    BigbluebuttonMeeting.find_each do |meeting|
      if meeting.recording.present?
        meeting.update_attributes(title: meeting.recording.description)
      end
    end

    remove_column :bigbluebutton_recordings, :description
  end

  def self.down
    add_column :bigbluebutton_recordings, :description, :string
    remove_column :bigbluebutton_meetings, :title
    remove_column :bigbluebutton_recordings, :state
    rename_column :bigbluebutton_servers, :slug, :param
    rename_column :bigbluebutton_rooms, :slug, :param
  end
end
