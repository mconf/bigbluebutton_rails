class BigbluebuttonRailsTo201 < ActiveRecord::Migration
  def change
    add_column :bigbluebutton_recordings, :size, :integer, default: 0
  end
end