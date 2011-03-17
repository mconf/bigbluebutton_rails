class BigbluebuttonRailsCreate < ActiveRecord::Migration

  def self.up
    create_table :bbb_servers do |t|
      t.string :name
      t.string :url
      t.salt :salt
      t.timestamps
    end
    create_table :bbb_rooms do |t|
      t.integer :bbb_server_id
      t.string :meeting_id
      t.string :meeting_name
      t.string :attendee_password
      t.string :moderator_password
      t.string :welcome_msg
      t.timestamps
    end
    add_index :bbb_rooms, :bbb_server_id
    add_index :bbb_rooms, :meeting_id, :unique => true
  end

  def self.down
    drop_table :bbb_rooms
    drop_table :bbb_servers
  end

end
