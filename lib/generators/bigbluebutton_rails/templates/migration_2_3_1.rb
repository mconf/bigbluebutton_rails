class BigbluebuttonRailsTo231 < ActiveRecord::Migration
  def change
    add_index :bigbluebutton_meetings, [:room_id, :create_time], using: 'btree',
              name: 'bigbluebutton_meetings_room_id_IDX'

    add_index :bigbluebutton_rooms, [:param], using: 'btree',
              name: 'bigbluebutton_rooms_param_IDX'

    add_index :bigbluebutton_metadata, [:owner_id, :owner_type, :name], using: 'btree',
              name: 'bigbluebutton_metadata_owner_id_IDX'
  end
end
