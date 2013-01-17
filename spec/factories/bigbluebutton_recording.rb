FactoryGirl.define do
  factory  :bigbluebutton_recording do |r|
    r.association :room, :factory => :bigbluebutton_room
    r.sequence(:recordingid) { |n| "rec#{n}" + SecureRandom.hex(26) }
    r.meetingid { "meeting" + SecureRandom.hex(8) }
    r.sequence(:name) { |n| "Rec #{n}" }
    r.published true
    r.start_time { Time.now - rand(5).hours }
    r.end_time { Time.now + rand(5).hours }
  end
end
