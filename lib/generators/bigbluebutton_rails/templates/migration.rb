class CreateBigbluebuttonRails < ActiveRecord::Migration

  def self.up
    create_table :bigbluebutton_servers do |t|
      t.string :name
      t.string :url
      t.string :salt
      t.string :version
      t.string :param
      t.timestamps
    end

    create_table :bigbluebutton_rooms do |t|
      t.integer :server_id
      t.integer :owner_id
      t.string :owner_type
      t.string :meetingid
      t.string :name
      t.string :attendee_key
      t.string :moderator_key
      t.string :welcome_msg
      t.string :logout_url
      t.string :voice_bridge
      t.string :dial_number
      t.integer :max_participants
      t.boolean :private, :default => false
      t.boolean :external, :default => false
      t.string :param
      t.boolean :record_meeting, :default => false
      t.integer :duration, :default => 0
      t.string :attendee_api_password
      t.string :moderator_api_password
      t.decimal :create_time, precision: 14, scale: 0
      t.string :moderator_only_message
      t.boolean :auto_start_recording, default: false
      t.boolean :allow_start_stop_recording, default: true
      t.timestamps
    end
    add_index :bigbluebutton_rooms, :server_id
    add_index :bigbluebutton_rooms, :meetingid, :unique => true

    create_table :bigbluebutton_room_options do |t|
      t.integer :room_id
      t.string :default_layout
      t.boolean :presenter_share_only
      t.boolean :auto_start_video
      t.boolean :auto_start_audio
      t.string :background
      t.timestamps
    end
    add_index :bigbluebutton_room_options, :room_id

    create_table :bigbluebutton_recordings do |t|
      t.integer :server_id
      t.integer :room_id
      t.integer :meeting_id
      t.string :recordid
      t.string :meetingid
      t.string :name
      t.boolean :published, :default => false
      t.datetime :start_time
      t.datetime :end_time
      t.boolean :available, :default => true
      t.string :description
      t.integer :size, limit: 8, default: 0
      t.timestamps
    end
    add_index :bigbluebutton_recordings, :room_id
    add_index :bigbluebutton_recordings, :recordid, :unique => true

    create_table :bigbluebutton_metadata do |t|
      t.integer :owner_id
      t.string :owner_type
      t.string :name
      t.text :content
      t.timestamps
    end

    create_table :bigbluebutton_playback_formats do |t|
      t.integer :recording_id
      t.integer :playback_type_id
      t.string :url
      t.integer :length
      t.timestamps
    end

    create_table :bigbluebutton_playback_types do |t|
      t.string :identifier
      t.boolean :visible, :default => false
      t.boolean :default, :default => false
      t.timestamps
    end

    create_table :bigbluebutton_meetings do |t|
      t.integer :server_id
      t.integer :room_id
      t.string :meetingid
      t.string :name
      t.datetime :start_time
      t.boolean :running, :default => false
      t.boolean :recorded, :default => false
      t.integer :creator_id
      t.string :creator_name
      t.timestamps
    end
    add_index :bigbluebutton_meetings, [:meetingid, :start_time], :unique => true

    create_table :bigbluebutton_server_configs do |t|
      t.integer :server_id
      t.text :available_layouts
      t.timestamps
    end
  end

  def self.down
    drop_table :bigbluebutton_meetings
    drop_table :bigbluebutton_playback_formats
    drop_table :bigbluebutton_playback_types
    drop_table :bigbluebutton_metadata
    drop_table :bigbluebutton_recordings
    drop_table :bigbluebutton_rooms
    drop_table :bigbluebutton_rooms_options
    drop_table :bigbluebutton_servers
    drop_table :bigbluebutton_server_configs
  end

end
