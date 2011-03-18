Factory.define :bigbluebutton_server do |s|
  s.sequence (:name) { |n| "Server #{n}" }
  s.sequence (:url) { |n| "http://bigbluebutton#{n}.test.com" }
  s.salt { Forgery(:basic).password }
#  s.salt { Forgery::Basic.password(:at_least => 35) }
end
