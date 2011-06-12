class BigbluebuttonRailsTo005 < ActiveRecord::Migration

  def self.up
    add_column :bigbluebutton_rooms, :external, :boolean, :default => false
  end

  def self.down
    remove_column :bigbluebutton_rooms, :external
  end

end
