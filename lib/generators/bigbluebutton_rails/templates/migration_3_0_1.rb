class BigbluebuttonRailsTo301 < ActiveRecord::Migration
  def self.change
    add_index :bigbluebutton_meetings, [:room_id, :create_time], using: 'btree'
    add_index :bigbluebutton_rooms, [:slug], using: 'btree'
    add_index :bigbluebutton_metadata, [:owner_id, :owner_type, :name], using: 'btree'
  end
end
