When /^(\d+) meetings running in this server$/ do |count|
  msalt = FeaturesConfig.server.has_key?('mobile_salt') ? FeaturesConfig.server['mobile_salt'] : ""
  @rooms = []
  count.to_i.times do |i|
    room = FactoryGirl.create(:bigbluebutton_room, :server => @server)
    BigBlueButtonBot.new(@server.api, room.meetingid, msalt, 1,
                         FeaturesConfig.root['timeout_bot_start'])
    @rooms << room
  end
end

When /^(\d+) meetings recently ended in this server$/ do |count|
  msalt = FeaturesConfig.server.has_key?('mobile_salt') ? FeaturesConfig.server['mobile_salt'] : ""
  @ended_rooms = []
  count.to_i.times do |i|
    room = FactoryGirl.create(:bigbluebutton_room, :server => @server)
    BigBlueButtonBot.new(@server.api, room.meetingid, msalt, 1,
                         FeaturesConfig.root['timeout_bot_start'])
    BigBlueButtonBot.finalize(room.meetingid)
    sleep 1
    @ended_rooms << room
  end
end

When /^he should see the (\d+) meetings that are running$/ do |count|
  check_server_activity_monitor_rooms(@rooms)
end

When /^he should see the external room in the list$/ do
  check_server_activity_monitor_rooms([@room])
end

When /^he should see the (\d+) recently ended meetings$/ do |count|
  check_server_activity_monitor_rooms(@ended_rooms)
end

When /^the first meeting is ended$/ do
  @rooms.first.send_end
  BigBlueButtonBot.finalize(@rooms.first.meetingid)
  sleep 1 # give the bot some time to finish
end

When /^he clicks in the link to update the meeting list$/ do
  find(make_selector("a.bbbrails_refresh_now")).click
end

When /^he should see one meeting running and the other meeting not running$/ do
  # first was ended, second is running
  @rooms.first.fetch_is_running?
  @rooms.first.is_running?.should be_false
  @rooms.last.fetch_is_running?
  @rooms.last.is_running?.should be_true

  # the ended meeting won't appear in the list in BBB 0.8
  @rooms.delete(@rooms.first) if @server.version >= "0.8"

  check_server_activity_monitor_rooms(@rooms)
end

When /^after (\d+) seconds$/ do |count|
  sleep count.to_i
end

# checks the rooms inside the activity monitor
def check_server_activity_monitor_rooms(rooms)
  within(make_selector("div#bbbrails_server_activity_meetings")) do
    rooms.each do |room|

      # restrict the search to this room's div
      xpath = ".//div[@class=\"bbbrails_meeting_description\" and contains(., \"#{room.meetingid}\")]"
      within(find(:xpath, xpath)) do

        # FIXME in bbb 0.7 get_meeting_info didn't return the room's name, only
        #       the meeting_id, so the name in the obj will be == meeting_id
        #       See BigbluebuttonServer#fetch_meetings
        has_content(room.name) unless room.new_record?
        has_content(room.meetingid)

        method = room.new_record? ? method(:doesnt_have_element) : method(:has_element)
        method.call("a", { :href => bigbluebutton_room_path(room) })
        method.call("a", { :href => edit_bigbluebutton_room_path(room) })
        method.call("a", { :href => bigbluebutton_room_path(room), :"data-method" => :delete })
        method.call("a", { :href => join_bigbluebutton_room_path(room) })
        method.call("a", { :href => join_mobile_bigbluebutton_room_path(room) })
        method.call("a", { :href => end_bigbluebutton_room_path(room) })

        room.fetch_is_running?
        if room.is_running?
          has_content(room.start_time)
          has_element("span.running")
          room.participant_count.times do |i|
            has_content("Bot #{i}") # user name
          end
        else
          has_content(room.start_time)
          has_content(room.end_time)
          has_element("span.not_running")
        end
      end

    end
  end
end
