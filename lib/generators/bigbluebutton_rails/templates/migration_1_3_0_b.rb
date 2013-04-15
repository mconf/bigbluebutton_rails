class BigbluebuttonRailsTo130B < ActiveRecord::Migration

  def self.up
    # Generate a meetingID for every room
    BigbluebuttonRoom.all.each do |room|
      room.update_attributes(:meetingid => room.unique_meetingid)
    end
  end

  def self.down
    # Can't undo
  end
end
