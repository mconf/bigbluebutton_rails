class BigbluebuttonRailsTo310B < ActiveRecord::Migration
  def up
    add_column :bigbluebutton_meetings, :internal_meeting_id, :string
    drop_table :bigbluebutton_server_configs
    drop_table :bigbluebutton_room_options
  end

  def down
    remove_column :bigbluebutton_meetings, :internal_meeting_id
  end
end
