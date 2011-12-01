When /^change the room name to "(.*)"$/ do |name|
  fill_in("bigbluebutton_room[name]", :with => name)
end

When /^click in the button to save the room$/ do
  find(:css, "input#bigbluebutton_room_submit").click
end

Then /^the room name should( not)? be "(.+)"$/i do |negate, name|
  if negate.nil?
    BigbluebuttonRoom.first.name.should == name
  else
    BigbluebuttonRoom.first.name.should_not == name
  end
end
