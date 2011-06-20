class BigbluebuttonRailsTo005 < ActiveRecord::Migration

  def self.up
    add_column :bigbluebutton_rooms, :external, :boolean, :default => false
    add_column :bigbluebutton_rooms, :param, :string
    add_column :bigbluebutton_servers, :param, :string
  end

  def self.down
    remove_column :bigbluebutton_rooms, :external
    remove_column :bigbluebutton_rooms, :param
    remove_column :bigbluebutton_servers, :param
  end

end
