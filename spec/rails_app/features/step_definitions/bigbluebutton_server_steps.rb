Given /a user named "(.+)"/i do |username|
  @username = username
  # TODO useless for now
end

When /(?:|I ) go(es)? to (.+) page$/i do |_, page_name|
  visit path_to(page_name)
end

And /^registers a new BigBlueButton server$/i do
  attrs = Factory.attributes_for(:bigbluebutton_server_integration)
  fill_in("Name", :with => attrs[:name])
  fill_in("URL", :with => attrs[:url])
  fill_in("Salt", :with => attrs[:salt])
  fill_in("Version", :with => attrs[:version])
  click_button("Create")
end

Then /(?:|I ) should see its information/ do
  server = BigbluebuttonServer.last
  page_has_content(server.name)
  page_has_content(server.url)
  page_has_content(server.salt)
  page_has_content(server.version)
end
