FactoryGirl.define do
  factory  :bigbluebutton_metadata do |r|
    r.association :owner, :factory => :bigbluebutton_recording
    r.sequence(:name) { |n| "#{Forgery(:name).first_name.downcase}-#{n}" }
    r.content { Forgery(:name).full_name }

    factory :bigbluebutton_room_metadata do |f|
      f.association :owner, :factory => :bigbluebutton_room
    end
  end
end
