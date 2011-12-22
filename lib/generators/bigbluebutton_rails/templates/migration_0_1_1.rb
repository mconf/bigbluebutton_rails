class BigbluebuttonRailsTo011 < ActiveRecord::Migration

  def self.up
    remove_index :bigbluebutton_rooms, :server_id
    remove_column :bigbluebutton_rooms, :server_id
  end

  def self.down
    add_column :bigbluebutton_rooms, :server_id, :integer
    add_index :bigbluebutton_rooms, :server_id
  end

end
