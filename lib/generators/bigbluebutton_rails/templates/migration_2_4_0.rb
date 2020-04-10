class BigbluebuttonRailsTo240 < ActiveRecord::Migration
  def change
    drop_table :bigbluebutton_server_configs
    drop_table :bigbluebutton_room_options
  end
end
