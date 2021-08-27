class BigbluebuttonRailsTo331 < ActiveRecord::Migration
  def self.up
    remove_column :bigbluebutton_rooms, :create_time
  end

  def self.down
    add_column :create_time, precision: 14, scale: 0
  end
end