class BigbluebuttonRailsTo240 < ActiveRecord::Migration
  def change
    drop_table :bigbluebutton_server_configs
  end
end
