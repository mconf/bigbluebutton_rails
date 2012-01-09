When /^he should see a form to join the external room$/i do
  check_template("join external room")
end

When /^he should see his name in the user name input$/i do
  case current_url
  when /\/invite$/          # normal rooms
    form = form_selector(join_bigbluebutton_room_path(@room), 'post')
  when /\/external(\?.*)?/  # external rooms
    form = form_selector(external_bigbluebutton_rooms_path, 'post')
  end
  within(form) do
    has_element("input", { :name => 'user[name]', :type => 'text', :value => @user.name })
  end
end

When /^he should( not)? join the conference room$/i do |negate|
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

When /^the password field was pre-filled with the attendee password$/ do
  has_element("input", { :name => 'user[password]', :type => 'password', :value => @room.attendee_password })
end
