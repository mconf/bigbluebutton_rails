When /^change the server URL to "(.+)"$/ do |url|
  fill_in("bigbluebutton_server[url]", :with => url)
end

When /^click in the button to save the server$/ do
  find(:css, "input#bigbluebutton_server_submit").click
end

Then /^the server URL should( not)? be "(.+)"$/i do |negate, url|
  if negate.nil?
    BigbluebuttonServer.first.url.should == url
  else
    BigbluebuttonServer.first.url.should_not == url
  end
end
