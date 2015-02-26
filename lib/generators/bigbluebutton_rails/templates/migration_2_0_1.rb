class BigbluebuttonRailsTo201 < ActiveRecord::Migration

  def self.up
    create_table :bigbluebutton_server_configs do |t|
      t.integer :server_id
      t.text :available_layouts
      t.timestamps
    end
  end

  def self.down
    drop_table :bigbluebutton_server_configs
  end
end
