When /^registers a new server$/i do
  attrs = Factory.attributes_for(:bigbluebutton_server_integration)
  fill_in("bigbluebutton_server[name]", :with => attrs[:name])
  fill_in("bigbluebutton_server[url]", :with => attrs[:url])
  fill_in("bigbluebutton_server[salt]", :with => attrs[:salt])
  fill_in("bigbluebutton_server[version]", :with => attrs[:version])
  fill_in("bigbluebutton_server[param]", :with => attrs[:param])
  click_button("Create")
end

When /^registers a new server with a wrong URL$/i do
  attrs = Factory.attributes_for(:bigbluebutton_server_integration)
  fill_in("bigbluebutton_server[name]", :with => attrs[:name])
  fill_in("bigbluebutton_server[url]", :with => "invalid url")
  fill_in("bigbluebutton_server[salt]", :with => attrs[:salt])
  fill_in("bigbluebutton_server[version]", :with => attrs[:version])
  fill_in("bigbluebutton_server[param]", :with => attrs[:param])
  click_button("Create")
end

When /(?:|I ) should see the information about this server/ do
  server = BigbluebuttonServer.last
  page_has_content(server.name)
  page_has_content(server.url)
  page_has_content(server.salt)
  page_has_content(server.version)
  page_has_content(server.param)
end

When /^see an error in the field (.+)$/i do |field_name|
  within(make_selector("#error_explanation")) do
    has_content("1 error prohibited this bigbluebutton_server from being saved")
    has_content("URL")
  end
  within(make_selector("div.field_with_errors:last")) do
    has_element("input", { :name => 'bigbluebutton_server[url]', :type => 'text' })
  end
  # TODO check label
end
