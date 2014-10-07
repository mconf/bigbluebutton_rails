FactoryGirl.define do
  factory :bigbluebutton_playback_type do |pbt|
    pbt.sequence(:identifier) { |n| "#{Forgery(:name).first_name.downcase}-#{n}" }
    pbt.visible true
    pbt.sequence(:i18n_key) { |n| "bigbluebutton_rails.playback_types.#{Forgery(:name).first_name.downcase}-#{n}" }
  end
end
