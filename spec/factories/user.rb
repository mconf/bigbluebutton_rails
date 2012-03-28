FactoryGirl.define do
  factory :user do |u|
    u.name { Forgery(:name).full_name }
  end
end
