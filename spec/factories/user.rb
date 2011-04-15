Factory.define :user do |u|
  u.name { Forgery(:name).full_name }
end
