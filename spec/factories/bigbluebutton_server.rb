FactoryBot.define do
  factory :bigbluebutton_server do |s|
    s.sequence(:name) { |n| "Server #{n}" }
    s.sequence(:url) { |n| "http://bigbluebutton#{n}.test.com/bigbluebutton/api" }
    s.secret { Forgery(:basic).password :at_least => 30, :at_most => 40 }
    s.version {'0.9'}
    s.sequence(:slug) { |n| "server-#{n}" }
  end

  after(:create) do |s|
    s.updated_at = s.updated_at.change(:usec => 0)
    s.created_at = s.created_at.change(:usec => 0)
  end
end
