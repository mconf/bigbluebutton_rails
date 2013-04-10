class BigbluebuttonRailsTo130b < ActiveRecord::Migration

  def self.up
    # Generate a meetingID for every room
    BigbluebuttonRoom.all.each do |room|
      room.meetingid = room.unique_meetingid
      room.save!
    end
  end

  def self.down
    # Can't undo
  end
end
