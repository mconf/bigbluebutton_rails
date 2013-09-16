When /^a real server$/i do
  @server = FactoryGirl.create(:bigbluebutton_server_integration)
end

When /^(\d+) server(s)?$/i do |count, _|
  # Note: these servers are not real, it will NOT be possible to make api requests
  #       for a real server use :bigbluebutton_server_integration
  count.to_i.times do
    FactoryGirl.create(:bigbluebutton_server)
  end
end

When /^a(n external)? room in this server$/i do |external|
  if external.nil?
    @room = FactoryGirl.create(:bigbluebutton_room, :server => @server)
  else
    @room = FactoryGirl.build(:bigbluebutton_room, :server => @server, :external => true)
  end
  @room.send_create
end

When /^an external room in this server with a meeting running$/i do
  @room = FactoryGirl.build(:bigbluebutton_room, :server => @server, :external => true)
  # can't call a create to this run because the bot will do so
  steps %Q{ When a meeting is running in this room with 1 attendees }
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
    @params = { :meeting => @room.meetingid, :server_id => @server.id }
  end
  visit path_to(page_name, @params)
end

When /see the (.+) page$/i do |page_name|
  opts = {
    :room => @room, :server => @server,
    :rooms => BigbluebuttonRoom.all, :servers => BigbluebuttonServer.all
  }
  check_template(page_name, opts)
end

When /a user named "(.+)"/i do |username|
  @user = FactoryGirl.build(:user, :name => username)
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

When /^a meeting is running in this room$/ do
  steps %Q{ When a meeting is running in this room with 1 attendees }
end

When /^a meeting is running in this room with (\d+) attendees$/ do |count|
  msalt = FeaturesConfig.server.has_key?('mobile_salt') ? FeaturesConfig.server['mobile_salt'] : ""
  BigBlueButtonBot.new(@server.api, @room.meetingid, msalt,
                       count.to_i, FeaturesConfig.root['timeout_bot_start'])
end


# helpers for development

When /is pending/i do
  pending
end

When /puts the page/i do
  puts current_url
  puts body.inspect
end
