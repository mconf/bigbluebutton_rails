class BigbluebuttonRailsTo312 < ActiveRecord::Migration
  def self.up
    change_column :bigbluebutton_meetings, :title, :text, limit: 255
  end

  def self.down
    change_column :bigbluebutton_meetings, :title, :string, limit: 80
  end
end