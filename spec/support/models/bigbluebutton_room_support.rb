# # how to isolate this?

module BigbluebuttonRoomSupport

  def create_room_without_meetings()
    room = FactoryBot.create(:bigbluebutton_room)
    RSpec::Core::ExampleGroup.it_behaves_like :RoomWithNoMeetings, room: room
    room
  end

  def create_room_with_meetings(ended: false,
                                meetings_count: 1,
                                create_time: Time.now)
    room = FactoryBot.create(:bigbluebutton_room_with_meetings,
                               meetings_count: meetings_count,
                               last_meeting_running: !ended,
                               last_meeting_ended: ended,
                               last_meeting_create_time: create_time)
    # RSpec::Core::ExampleGroup.it_behaves_like :RoomWithMeetings, { room: room,
    #                                      meetings_count: meetings_count,
    #                                      last_meeting_running: !ended,
    #                                      last_meeting_ended: ended,
    #                                      last_meeting_create_time: create_time }
    room
  end
end

