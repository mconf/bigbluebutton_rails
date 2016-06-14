FactoryGirl.define do
  factory :bigbluebutton_server_integration, :parent => :bigbluebutton_server do |s|
    s.url { FeaturesConfig.server["url"] }
    s.secret { FeaturesConfig.server["secret"] }
    s.version { FeaturesConfig.server["version"] }
  end
end
