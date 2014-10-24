FactoryGirl.define do
  factory :bigbluebutton_meeting do |m|
    m.sequence(:meetingid) { |n| "meeting-#{n}-" + SecureRandom.hex(4) }
    m.association :server, :factory => :bigbluebutton_server
    m.association :room, :factory => :bigbluebutton_room
    m.sequence(:name) { |n| "Name#{n}" }
    m.recorded false
    m.running false
    m.start_time { Time.at(Time.now.to_i + rand(999999)) }
    # m.creator_id
    # m.creator_name
  end
end
