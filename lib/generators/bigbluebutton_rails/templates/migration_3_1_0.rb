class BigbluebuttonRailsTo310 < ActiveRecord::Migration
  class BigbluebuttonMeeting < ActiveRecord::Base
    has_one :recording,
            :class_name => 'BigbluebuttonRailsTo310::BigbluebuttonRecording',
            :foreign_key => 'meeting_id',
            :dependent => :destroy
  end

  class BigbluebuttonRecording < ActiveRecord::Base
    has_many  :metadata,
              :class_name => 'BigbluebuttonRailsTo310::BigbluebuttonMetadata',
              :as => :owner,
              :dependent => :destroy

    belongs_to :meeting, class_name: 'BigbluebuttonRailsTo310::BigbluebuttonMeeting'
    belongs_to :server, class_name: 'BigbluebuttonRailsTo310::BigbluebuttonServer'

    validates :server, :presence => true
  end

  class BigbluebuttonMetadata < ActiveRecord::Base
  end

  class BigbluebuttonServer < ActiveRecord::Base
  end

  def up
    BigbluebuttonRecording.where(meeting_id: nil).where.not(room_id: nil).find_each do |recording|
      attrs = {
        server_id: recording.server.id,
        room_id: recording.room_id,
        meetingid: recording.meetingid,
        name: recording.name,
        running: false,
        recorded: true,
        creator_id: nil,
        creator_name: nil,
        server_url: recording.server.url,
        server_secret: recording.server.secret,
        create_time: recording.start_time * 1000,
        ended: true,
        finish_time: recording.end_time,
        title: recording.name
      }

      if recording.metadata.present?
        attrs[:creator_id] = recording.metadata.find_by(name: 'bbbrails-user-id').content.to_i
        attrs[:creator_name] = recording.metadata.find_by(name: 'bbbrails-user-name').content
      end

      meeting = BigbluebuttonMeeting.create(attrs)
      recording.update_attributes(meeting_id: meeting.id)
      puts "Created a meeting for the recording id-#{recording.id}: Meeting id-#{meeting.id}"
    end
  end

  def down
    create_table :bigbluebutton_server_configs do |t|
      t.integer :server_id
      t.text :available_layouts
      t.timestamps
    end

    create_table :bigbluebutton_room_options do |t|
      t.integer :room_id
      t.string :default_layout
      t.boolean :presenter_share_only
      t.boolean :auto_start_video
      t.boolean :auto_start_audio
      t.string :background
      t.timestamps
    end
    
    raise ActiveRecord::IrreversibleMigration, "Can't undo due to loss of values during migration"
  end
end
