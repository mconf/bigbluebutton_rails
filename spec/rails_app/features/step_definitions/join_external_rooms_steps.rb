When /^an external room$/i do
  @room = Factory.build(:bigbluebutton_room, :server => @server, :external => true)
  @room.meetingid << "-" + SecureRandom.hex(4) # to avoid failures due to duplicated meeting_id's
  @room.send_create
end

When /^he should see a form to join the external room$/i do
  within(form_selector(external_bigbluebutton_server_rooms_path(@server), 'post')) do
    has_element("input", { :name => 'meeting', :type => 'hidden', :value => @room.meetingid })
    has_element("input", { :name => 'user[name]', :type => 'text' })
    has_element("input", { :name => 'user[password]', :type => 'password' })
  end
end

When /^he should see his name should be in the user name input$/i do
  within(form_selector(external_bigbluebutton_server_rooms_path(@server), 'post')) do
    has_element("input", { :name => 'user[name]', :type => 'text', :value => @user.name })
  end
end

When /^he should( not)? be able to join the room$/i do |negate|
  click_button("Submit")
  if negate.nil?
    current_url.should match(/\/client\/BigBlueButton\.html/) # BBB client page
  else
    current_url.should_not match(/\/client\/BigBlueButton\.html/)
  end
end

When /^enters his name and the (.+) password$/i do |role|
  name = @user.nil? ? "Anonymous" : @user.name
  password = role.downcase.to_sym == :moderator ? @room.moderator_password : @room.attendee_password
  fill_in("user[name]", :with => name)
  fill_in("user[password]", :with => password)
end

When /^enters only the (.+) password$/ do |role|
  password = role.downcase.to_sym == :moderator ? @room.moderator_password : @room.attendee_password
  fill_in("user[password]", :with => password)
  fill_in("user[name]", :with => "")
end

When /^enters only the user name$/ do
  name = @user.nil? ? "Anonymous" : @user.name
  fill_in("user[name]", :with => name)
end
