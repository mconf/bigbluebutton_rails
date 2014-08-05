When /^he should see his name in the user name input$/i do
  case current_url
  when /\/invite$/          # normal rooms
    form = form_selector(join_bigbluebutton_room_path(@room), 'post')
  end
  within(form) do
    has_element("input", { :name => 'user[name]', :type => 'text', :value => @user.name })
  end
end

When /^he should( not)? join the conference room$/i do |negate|
  if negate.nil?
    current_url.should match(/\/client\/MconfLive\.html/) # BBB client page
  else
    current_url.should_not match(/\/client\/MconfLive\.html/)
  end
end

When /^enters his name and the (.+) key$/i do |role|
  name = @user.nil? ? "Anonymous" : @user.name
  key = role.downcase.to_sym == :moderator ? @room.moderator_key : @room.attendee_key
  fill_in("user[name]", :with => name)
  fill_in("user[key]", :with => key)
end

When /^enters only the (.+) key$/ do |role|
  key = role.downcase.to_sym == :moderator ? @room.moderator_key : @room.attendee_key
  fill_in("user[key]", :with => key)
  fill_in("user[name]", :with => "")
end

When /^enters only the user name$/ do
  name = @user.nil? ? "Anonymous" : @user.name
  fill_in("user[name]", :with => name)
end

When /^the read-only key field was pre-filled with the moderator key$/ do
  has_element("input", { :name => 'user[key]', :type => 'password', :value => @room.moderator_key, :readonly => 'readonly' })
end

When /^the key field was not pre-filled$/i do
  has_element("input", { :name => 'user[key]', :type => 'password', :value => '' })
end

When /^the read-only name field was pre-filled with "(.+)"$/ do |name|
  has_element("input", { :name => 'user[name]', :type => 'text', :value => name, :readonly => 'readonly' })
end

When /^the name field was not pre-filled$/i do
  has_element("input", { :name => 'user[name]', :type => 'text', :value => ''})
end

When /^the action in the form should point to the mobile join$/i do
  action = join_bigbluebutton_room_path(@room, :mobile => true)
  has_element("form", { :action => action, :method => 'post' })
end

When /^he should see a link to join the conference from a desktop$/i do
  has_element("a", { :href => invite_bigbluebutton_room_path(@room) })
end

When /^he should see a link to join the conference from a mobile device$/i do
  has_element("a", { :href => invite_bigbluebutton_room_path(@room, :mobile => true) })
end

# Joining a conference with mobile=true will redirect the user to a url
# using the protocol "bigbluebutton://" and Mechanize will throw an exception
# because it doesn't know the protocol. So we check the url using this exception.
When /^clicks in the button to join the conference from a mobile device$/i do
  begin
    click_button("Submit")
  rescue Exception => @exception
  end
end
When /^he should be redirected to the conference using the "bigbluebutton:\/\/" protocol$/i do
  @exception.message.should match(/bigbluebutton:\/\//)
end
