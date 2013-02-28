FactoryGirl.define do
  factory :user do |u|
    u.sequence(:id) { |n| n }
    u.name { Forgery(:name).full_name }
  end
end
