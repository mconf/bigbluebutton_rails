Factory.define :bigbluebutton_server_integration, :parent => :bigbluebutton_server do |s|
  s.url { FeaturesConfig.server["url"] }
  s.salt { FeaturesConfig.server["salt"] }
  s.version { FeaturesConfig.server["version"] }
end
