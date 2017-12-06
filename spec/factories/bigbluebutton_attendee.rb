FactoryGirl.define do
  factory :bigbluebutton_attendee do |a|
    a.sequence(:user_id) { |n| "userid-#{n}" }
    a.sequence(:user_name) { |n| "User Full Name #{n}" }
    a.association :meeting, :factory => :bigbluebutton_meeting
  end
end
