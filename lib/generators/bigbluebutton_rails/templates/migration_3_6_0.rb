class BigbluebuttonRailsTo360 < ActiveRecord::Migration
  def self.up
    add_column :bigbluebutton_recordings, :expiration_date, :decimal, precision: 14, scale: 0
  end
  
  def self.down
    remove_column :bigbluebutton_recordings, :expiration_date
  end
end