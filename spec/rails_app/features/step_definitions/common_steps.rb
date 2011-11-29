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
end

When /(?:|I ) should be at the (.+) URL$/i do |page_name|
  current_url.should match(/#{path_to(page_name)}/)
end

When /see the (.+) page$/i do |page_name|
  check_template(page_name)
end

When /is pending/i do
  pending
end
