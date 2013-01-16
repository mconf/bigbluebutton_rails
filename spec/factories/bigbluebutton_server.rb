FactoryGirl.define do
  factory :bigbluebutton_server do |s|
    s.sequence(:name) { |n| "Server #{n}" }
    s.sequence(:url) { |n| "http://bigbluebutton#{n}.test.com/bigbluebutton/api" }
    s.salt { Forgery(:basic).password :at_least => 30, :at_most => 40 }
    s.version '0.8'
    s.sequence(:param) { |n| "server-#{n}" }
  end
end
