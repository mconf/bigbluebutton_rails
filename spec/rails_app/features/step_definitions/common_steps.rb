When /(?:|I ) go(es)? to the (.+) page$/i do |_, page_name|
  visit path_to(page_name, @params)
end

When /a user named "(.+)"/i do |username|
  # TODO: define (and login?) a real user
  @user = Factory.build(:user, :name => username)
end
