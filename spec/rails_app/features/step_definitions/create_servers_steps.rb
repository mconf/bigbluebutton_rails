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
  steps %Q{ When see the show server page }
end
