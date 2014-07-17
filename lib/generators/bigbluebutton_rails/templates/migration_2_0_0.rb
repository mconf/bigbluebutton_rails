class BigbluebuttonRailsTo200 < ActiveRecord::Migration

  def self.up
    rename_column :bigbluebutton_rooms, :record, :record_meeting
    rename_column :bigbluebutton_recordings, :record, :recorded
  end

  def self.down
    rename_column :bigbluebutton_rooms, :record_meeting, :record
    rename_column :bigbluebutton_recordings, :recorded, :record
  end
end
