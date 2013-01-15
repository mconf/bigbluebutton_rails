FactoryGirl.define do
  factory  :bigbluebutton_metadata do |r|
    r.association :recording, :factory => :bigbluebutton_recording
    r.name { Forgery(:lorem_ipsum).word }
    r.content { Forgery(:lorem_ipsum).words(4) }
  end
end
