class BigbluebuttonRailsTo210 < ActiveRecord::Migration
  def self.up
    add_column :bigbluebutton_meetings, :server_url, :string
    add_column :bigbluebutton_meetings, :server_shared_secret, :string
    add_column :bigbluebutton_meetings, :create_time, :decimal, precision: 14, scale: 0
    add_column :bigbluebutton_meetings, :ended, :boolean, :default => false
    remove_index :bigbluebutton_meetings, [:meetingid, :start_time]
    add_index :bigbluebutton_meetings, [:meetingid, :create_time], :unique => true
  end

  def self.down
    remove_column :bigbluebutton_meetings, :server_url
    remove_column :bigbluebutton_meetings, :server_shared_secret
    remove_column :bigbluebutton_meetings, :create_time
    remove_column :bigbluebutton_meetings, :ended
    remove_index :bigbluebutton_meetings, [:meetingid, :create_time]
    add_index :bigbluebutton_meetings, [:meetingid, :start_time], :unique => true
  end
end
