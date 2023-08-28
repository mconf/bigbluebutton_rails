FactoryBot.define do
  factory :bigbluebutton_meeting do |m|
    m.sequence(:meetingid) { |n| "meeting-#{n}-" + SecureRandom.hex(4) }
    m.association :room, :factory => :bigbluebutton_room
    m.sequence(:name) { |n| "Name#{n}" }
    m.recorded { false }
    m.running { false }
    m.ended { false }
    m.create_time { Time.now.to_i + rand(999999) }
    m.title { Forgery(:lorem_ipsum).words(1) }
    m.sequence(:internal_meeting_id) { |n| "rec#{n}-#{SecureRandom.uuid}-#{DateTime.now.to_i}" }
    # m.creator_id
    # m.creator_name
  end
end
