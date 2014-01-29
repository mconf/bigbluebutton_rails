FactoryGirl.define do
  factory :bigbluebutton_room_options do |r|
    r.sequence(:default_layout) { Forgery(:name).first_name.downcase }
    r.association :room, :factory => :bigbluebutton_room
  end
end
