FactoryGirl.define do
  factory  :bigbluebutton_playback_format do |r|
    r.association :recording, :factory => :bigbluebutton_recording
    r.sequence(:format_type) { |n| "#{Forgery(:name).first_name.downcase}-#{n}" }
    r.url { "http://" + Forgery(:internet).domain_name + "/playback" }
    r.length { Forgery(:basic).number }
  end
end
