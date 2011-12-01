When /^clicks in the link to remove the first room$/i do
  # there's only 1 room created, so only 1 "Destroy" link
  click_link("Destroy")
end

When /^the removed room should not be listed$/i do
  BigbluebuttonRoom.find_by_id(@room.id).should be_nil

  # check params that are specific for this server
  doesnt_have_content(@room.meetingid)
  doesnt_have_content(@room.name)
  doesnt_have_content(@room.attendee_password)
  doesnt_have_content(@room.moderator_password)
  doesnt_have_content(@room.voice_bridge)
  doesnt_have_content(@room.param)
end

