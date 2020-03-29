class BigbluebuttonRailsTo301 < ActiveRecord::Migration
  def self.change
    remove_index :bigbluebutton_rooms, [:param], using: 'btree',
              name: 'bigbluebutton_rooms_param_IDX'
    add_index :bigbluebutton_rooms, [:slug], using: 'btree'
  end
end
