class BigbluebuttonRailsTo130Mweb1 < ActiveRecord::Migration
  def self.up
    remove_index :bigbluebutton_rooms, :voice_bridge
  end

  def self.down
    add_index :bigbluebutton_rooms, :voice_bridge, :unique => true
  end
end
