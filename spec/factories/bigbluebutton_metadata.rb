FactoryGirl.define do
  factory  :bigbluebutton_metadata do |r|
    r.association :recording, :factory => :bigbluebutton_recording
    r.name { Forgery(:name).first_name.downcase }
    r.content { Forgery(:name).full_name }
  end
end
