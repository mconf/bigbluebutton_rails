Factory.define :bigbluebutton_room do |r|
  r.association :server, :factory => :bigbluebutton_server
  r.sequence(:meeting_id) { |n| "MeetingID#{n}" }
  r.sequence(:name) { |n| "Name#{n}" }
  r.attendee_password { Forgery(:basic).password :at_least => 10, :at_most => 20 }
  r.moderator_password { Forgery(:basic).password :at_least => 10, :at_most => 20 }
  r.welcome_msg { Forgery(:lorem_ipsum).sentences(2) }
end
