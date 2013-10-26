FactoryGirl.define do
  factory :bigbluebutton_recording do |r|
    r.association :server, :factory => :bigbluebutton_server
    r.association :room, :factory => :bigbluebutton_room
    r.association :meeting, :factory => :bigbluebutton_meeting
    r.meetingid { "meeting" + SecureRandom.hex(8) }
    r.sequence(:name) { |n| "Rec #{n}" }
    r.published true
    r.start_time { Time.now - rand(5).hours }
    r.end_time { Time.now + rand(5).hours }
    # TODO: should contain the meeting's start_time at the end
    r.sequence(:recordid) { |n| "rec#{n}-#{SecureRandom.uuid}-#{DateTime.now.to_i}" }
    r.available true
  end
end
