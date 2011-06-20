IntegrationConf.load
config = IntegrationConf.config["server"]

Factory.define :bigbluebutton_server_integration, :parent => :bigbluebutton_server do |s|
  s.url { config["url"] }
  s.salt { config["salt"] }
  s.version { config["version"] }
end
