class BigbluebuttonRailsTo140 < ActiveRecord::Migration
  def self.up
    add_column :bigbluebutton_recordings, :description, :string
    add_column :bigbluebutton_recordings, :meeting_id, :integer

    create_table :bigbluebutton_meetings do |t|
      t.integer :server_id
      t.integer :room_id
      t.string :meetingid
      t.string :name
      t.datetime :start_time
      t.boolean :running, :default => false
      t.boolean :record, :default => false
      t.integer :creator_id
      t.string :creator_name
      t.timestamps
    end
    add_index :bigbluebutton_meetings, [:meetingid, :start_time], :unique => true

    create_table :bigbluebutton_room_options do |t|
      t.integer :room_id
      t.string :default_layout
      t.boolean :presenter_share_only
      t.boolean :auto_start_video
      t.boolean :auto_start_audio
      t.timestamps
    end
    add_index :bigbluebutton_room_options, :room_id
  end

  def self.down
    drop_table :bigbluebutton_meetings
    drop_table :bigbluebutton_room_options
    remove_column :bigbluebutton_recordings, :meeting_id
    remove_column :bigbluebutton_recordings, :description
  end
end
