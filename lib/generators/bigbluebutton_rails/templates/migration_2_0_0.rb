class BigbluebuttonRailsTo200 < ActiveRecord::Migration

  def self.up
    create_table :bigbluebutton_playback_types do |t|
      t.string :identifier
      t.boolean :visible, :default => false
      t.boolean :default, :default => false
      t.timestamps
    end

    rename_column :bigbluebutton_rooms, :record, :record_meeting
    rename_column :bigbluebutton_meetings, :record, :recorded
    rename_column :bigbluebutton_rooms, :attendee_password, :attendee_key
    rename_column :bigbluebutton_rooms, :moderator_password, :moderator_key
    add_column :bigbluebutton_rooms, :moderator_api_password, :string
    add_column :bigbluebutton_rooms, :attendee_api_password, :string
    add_column :bigbluebutton_rooms, :create_time, :decimal, precision: 14, scale: 0
    remove_column :bigbluebutton_playback_formats, :format_type
    add_column :bigbluebutton_playback_formats, :playback_type_id, :integer
    remove_index :bigbluebutton_rooms, :voice_bridge

    create_table :bigbluebutton_server_configs do |t|
      t.integer :server_id
      t.text :available_layouts
      t.timestamps
    end
  end

  def self.down
    drop_table :bigbluebutton_playback_types
    rename_column :bigbluebutton_rooms, :record_meeting, :record
    rename_column :bigbluebutton_meetings, :recorded, :record
    rename_column :bigbluebutton_rooms, :attendee_key, :attendee_password
    rename_column :bigbluebutton_rooms, :moderator_key, :moderator_password
    remove_column :bigbluebutton_rooms, :moderator_api_password
    remove_column :bigbluebutton_rooms, :attendee_api_password
    remove_column :bigbluebutton_rooms, :create_time
    add_column :bigbluebutton_playback_formats, :format_type, :string
    remove_column :bigbluebutton_playback_formats, :playback_type_id
    add_index :bigbluebutton_rooms, :voice_bridge, :unique => true
    drop_table :bigbluebutton_server_configs
  end
end
