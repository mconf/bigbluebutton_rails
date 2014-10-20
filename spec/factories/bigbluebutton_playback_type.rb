FactoryGirl.define do
  factory :bigbluebutton_playback_type do |pbt|
    pbt.sequence(:identifier) { |n| "#{Forgery(:name).first_name.downcase}-#{n}" }
    pbt.visible true
  end
end
