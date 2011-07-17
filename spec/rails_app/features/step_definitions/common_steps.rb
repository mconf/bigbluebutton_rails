When /(?:|I ) go(es)? to the (.+) page$/i do |_, page_name|
  visit path_to(page_name, @params)
end

When /(?:|I ) go(es)? to the (.+) page for (.+)$/i do |_, page_name, param|
  case page_name
  when /join external room/i
    @params = { :meeting => @room.meetingid }
  end
  visit path_to(page_name, @params)
end

When /a user named "(.+)"/i do |username|
  @user = Factory.build(:user, :name => username)
  ApplicationController.set_user(@user) # This is now the logged user
end
