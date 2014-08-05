class BigbluebuttonRailsTo200 < ActiveRecord::Migration

  def self.up
    rename_column :bigbluebutton_rooms, :record, :record_meeting
    rename_column :bigbluebutton_recordings, :record, :recorded
    rename_column :bigbluebutton_rooms, :attendee_password, :attendee_key
    rename_column :bigbluebutton_rooms, :moderator_password, :moderator_key
  end

  def self.down
    rename_column :bigbluebutton_rooms, :record_meeting, :record
    rename_column :bigbluebutton_recordings, :recorded, :record
    rename_column :bigbluebutton_rooms, :attendee_key, :attendee_password
    rename_column :bigbluebutton_rooms, :moderator_key, :moderator_password
  end
end
