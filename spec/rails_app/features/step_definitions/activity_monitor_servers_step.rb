When /^(\d+) meetings running in this server$/ do |count|
  msalt = FeaturesConfig.server.has_key?('mobile_salt') ? FeaturesConfig.server['mobile_salt'] : ""
  @rooms = []
  count.to_i.times do |i|
    room = Factory.create(:bigbluebutton_room, :server => @server)
    room.send_create
    BigBlueButtonBot.new(@server.api, room.meetingid, msalt,
                         1, FeaturesConfig.root['timeout_bot_start'])
    @rooms << room
  end
end

When /^he should see the (\d+) meetings that are running$/ do |count|
  check_server_activity_monitor_rooms(@rooms)
end
