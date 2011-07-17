When /a server/i do
  @server = Factory.create(:bigbluebutton_server_integration)
end

When /^registers a new room$/i do
  attrs = Factory.attributes_for(:bigbluebutton_room, :server => @server)
  fill_in("bigbluebutton_room[name]", :with => attrs[:name])
  fill_in("bigbluebutton_room[meetingid]", :with => attrs[:meetingid])
  check("bigbluebutton_room[randomize_meetingid]") if attrs[:randomize_meetingid]
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

When /(?:|I ) should see the information about this room/i do
  room = BigbluebuttonRoom.last
  page_has_content(room.name)
  page_has_content(room.meetingid)
  page_has_content(room.randomize_meetingid)
  page_has_content(room.private)
  page_has_content(room.attendee_password)
  page_has_content(room.moderator_password)
  page_has_content(room.welcome_msg)
  page_has_content(room.logout_url)
  page_has_content(room.dial_number)
  page_has_content(room.voice_bridge)
  page_has_content(room.max_participants)
  page_has_content(room.external)
  page_has_content(room.param)
end

When /^an external room$/i do
  @room = Factory.build(:bigbluebutton_room, :server => @server, :external => true)
  @room.send_create
end

When /(?:|I ) should see a form to join the external room$/i do
  within(form_selector(external_bigbluebutton_server_rooms_path(@server), 'post')) do
    has_element("input", { :name => 'meeting', :type => 'hidden', :value => @room.meetingid })
    has_element("input", { :name => 'user[name]', :type => 'text' })
    has_element("input", { :name => 'user[password]', :type => 'password' })
  end
end

When /his name should be in the appropriate input$/i do
  within(form_selector(external_bigbluebutton_server_rooms_path(@server), 'post')) do
    has_element("input", { :name => 'user[name]', :type => 'text', :value => @user.name })
  end
end

When /^be able to join the room$/i do
  fill_in("user[name]", :with => @user.name)
  fill_in("user[password]", :with => @room.moderator_password)
  click_button("Submit")
  # TODO: check current_url to ensure it is inside the conference
end
