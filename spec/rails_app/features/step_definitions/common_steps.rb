When /^a real server$/i do
  @server = Factory.create(:bigbluebutton_server_integration)
end

When /^(\d+) server(s)?$/i do |count, _|
  # Note: these servers are not real, it will NOT be possible to make api requests
  #       for a real server use :bigbluebutton_server_integration
  # Use "a real server" whenever possible
  count.to_i.times do
    Factory.create(:bigbluebutton_server)
  end
end

When /^a(n external)? room in this server$/i do |external|
  if external.nil?
    @room = Factory.create(:bigbluebutton_room, :server => @server)
  else
    @room = Factory.build(:bigbluebutton_room, :server => @server, :external => true)
  end
  @room.send_create
end

When /^a public room in this server$/i do
  steps %Q{ When a room in this server }
  @room.update_attributes(:private => false)
end

When /^a private room in this server$/i do
  steps %Q{ When a room in this server }
  @room.update_attributes(:private => true)
end

When /^(\d+) room(s)? in this server$/i do |count, _|
  count.to_i.times do
    steps %Q{ When a room in this server }
  end
end

# Some paths will just redirect to other paths instead of rendering a view
# So we can set "(no view check)" and the view won't be verified
When /(?:|I ) go(es)? to the (.+) page( \(no view check\))?$/i do |_, page_name, not_check|
  case page_name
  when /join external room/i
    @params = { :meeting => @room.meetingid }
  end
  visit path_to(page_name, @params)
  check_template(page_name) if not_check.nil?
end

When /see the (.+) page$/i do |page_name|
  check_template(page_name)
end

When /a user named "(.+)"/i do |username|
  @user = Factory.build(:user, :name => username)
  ApplicationController.set_user(@user) # This is now the logged user
end

When /an anonymous user/i do
  @user = nil
  ApplicationController.set_user(@user)
end

When /(?:|I ) should be at the (.+) URL$/i do |page_name|
  current_url.should match(/#{path_to(page_name)}/)
end

When /^he should be redirected to the (.+) URL$/ do |page|
  steps %Q{ When he should be at the #{page} URL }
end

When /^(he )?should see an error message with the message "(.+)"$/i do |_, msg|
  key = message_to_locale_key(msg)
  within(make_selector("div#error_explanation")) do
    has_content(I18n.t(key))
  end
end

When /^see (\d+) error(s)? in the field "(.+)"$/i do |errors, _, field_name|
  within(make_selector("#error_explanation")) do
    errors.to_i == 1 ? has_content("1 error:") : has_content("#{errors} errors:")
  end
  id = field_name.gsub(/\]?\[/, "_").gsub(/\]/, "")
  has_element("div.field_with_errors > label", { :for => id })
  has_element("div.field_with_errors > input##{id}", { :name => field_name })
end

When /^clicks in the button "(.+)"$/i do |button|
  click_button(button)
end


# helpers for development

When /is pending/i do
  pending
end

When /puts the page/i do
  puts current_url
  puts body.inspect
end
