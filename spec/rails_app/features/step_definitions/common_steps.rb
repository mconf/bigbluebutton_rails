When /a server/i do
  @server = Factory.create(:bigbluebutton_server_integration)
end

When /(?:|I ) go(es)? to the (.+) page$/i do |_, page_name|
  visit path_to(page_name, @params)
end

When /(?:|I ) go(es)? to the (.+) page for (.+)$/i do |_, page_name, param|
  case page_name
  when /join external room/i
    @params = { :meeting => @room.meetingid }
  end
  visit path_to(page_name, @params)
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

When /see the (.+) page$/i do |page_name|
  check_template(page_name)
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

When /is pending/i do
  pending
end
