When /^registers a new room$/i do
  attrs = FactoryGirl.attributes_for(:bigbluebutton_room, :server => @server)
  fill_in("bigbluebutton_room[server_id]", :with => attrs[:server_id])
  fill_in("bigbluebutton_room[name]", :with => attrs[:name])
  fill_in("bigbluebutton_room[meetingid]", :with => attrs[:meetingid])
  check("bigbluebutton_room[private]") if attrs[:private]
  fill_in("bigbluebutton_room[attendee_password]", :with => attrs[:attendee_password])
  fill_in("bigbluebutton_room[moderator_password]", :with => attrs[:moderator_password])
  fill_in("bigbluebutton_room[welcome_msg]", :with => attrs[:welcome_msg])
  fill_in("bigbluebutton_room[logout_url]", :with => attrs[:logout_url])
  fill_in("bigbluebutton_room[dial_number]", :with => attrs[:dial_number])
  fill_in("bigbluebutton_room[max_participants]", :with => attrs[:max_participants])
  check("bigbluebutton_room[external]") if attrs[:external]
  fill_in("bigbluebutton_room[param]", :with => attrs[:param])
  # Note: voice_bridge is generated when the BigbluebuttonRoom is created
  click_button("Create")
end

When /^registers a new room with wrong parameters$/i do
  attrs = FactoryGirl.attributes_for(:bigbluebutton_room, :server => @server)
  fill_in("bigbluebutton_room[name]", :with => nil) # invalid
  fill_in("bigbluebutton_room[meetingid]", :with => attrs[:meetingid])
  check("bigbluebutton_room[private]") if attrs[:private]
  fill_in("bigbluebutton_room[attendee_password]", :with => attrs[:attendee_password])
  fill_in("bigbluebutton_room[moderator_password]", :with => attrs[:moderator_password])
  fill_in("bigbluebutton_room[welcome_msg]", :with => attrs[:welcome_msg])
  fill_in("bigbluebutton_room[logout_url]", :with => attrs[:logout_url])
  fill_in("bigbluebutton_room[dial_number]", :with => attrs[:dial_number])
  fill_in("bigbluebutton_room[max_participants]", :with => attrs[:max_participants])
  check("bigbluebutton_room[external]") if attrs[:external]
  fill_in("bigbluebutton_room[param]", :with => attrs[:param])
  click_button("Create")
end

When /(?:|I ) should see the information about this room/i do
  steps %Q{ When see the show room page }
end
