When /^he should see all available rooms in the list$/i do
  check_template("rooms index")
end

When /^he should see all the information available for this room$/i do
  check_template("show room", { :room => @room })
end

When /^(\d+) room(s)? in any other server$/i do |count, _|
  any_other_server = Factory.create(:bigbluebutton_server)
  count.to_i.times do
    Factory.create(:bigbluebutton_room, :server => any_other_server)
  end
end

When /^he should see only the rooms from this server$/i do
  check_template("server rooms", { :rooms => @server.rooms })
end
