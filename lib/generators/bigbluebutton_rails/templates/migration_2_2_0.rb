class BigbluebuttonRailsTo220 < ActiveRecord::Migration
  def self.up
    remove_column :bigbluebutton_meetings, :server_id
    remove_index :bigbluebutton_rooms, :server_id
    remove_column :bigbluebutton_rooms, :server_id
  end

  def self.down
    add_column :bigbluebutton_meetings, :server_id, :integer
    add_column :bigbluebutton_rooms, :server_id, :integer
    add_index :bigbluebutton_rooms, :server_id
  end
end
