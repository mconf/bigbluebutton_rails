FactoryGirl.define do
  factory :bigbluebutton_meeting do |m|
    m.sequence(:meetingid) { |n| "meeting-#{n}-" + SecureRandom.hex(4) }
    m.association :server, :factory => :bigbluebutton_server
    m.association :room, :factory => :bigbluebutton_room
    m.sequence(:name) { |n| "Name#{n}" }
    m.record false
    m.running false
    m.start_time { Time.now - rand(5).hours }
    # m.creator_id
    # m.creator_name
  end
end
