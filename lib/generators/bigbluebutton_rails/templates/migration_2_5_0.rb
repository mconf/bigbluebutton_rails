class BigbluebuttonRailsTo250 < ActiveRecord::Migration
  def self.up
    add_column :bigbluebutton_recordings, :state, :string
  end

  def self.down
    remove_column :bigbluebutton_recordings, :state
  end
end
