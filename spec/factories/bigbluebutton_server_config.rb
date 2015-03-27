FactoryGirl.define do
  factory :bigbluebutton_server_config do |c|
    c.available_layouts ["Web Conference", "Video", "Chat"]
    c.association :server, factory: :bigbluebutton_server
  end
end
