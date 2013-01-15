class BigbluebuttonRailsTo130 < ActiveRecord::Migration

  def self.up
    create_table :bigbluebutton_recordings do |t|
      t.integer :room_id
      t.string :recordingid
      t.string :meetingid
      t.string :name
      t.boolean :published, :default => false
      t.datetime :start_time
      t.datetime :end_time
      t.timestamps
    end
    add_index :bigbluebutton_recordings, :room_id
    add_index :bigbluebutton_recordings, :recordingid, :unique => true

    create_table :bigbluebutton_metadata do |t|
      t.integer :recording_id
      t.string :name
      t.text :content
      t.timestamps
    end

    create_table :bigbluebutton_playback_formats do |t|
      t.integer :recording_id
      t.string :type
      t.string :url
      t.integer :length
      t.timestamps
    end
  end

  def self.down
    drop_table :bigbluebutton_recordings
    drop_table :bigbluebutton_metadata
    drop_table :bigbluebutton_playback_formats
  end
end
