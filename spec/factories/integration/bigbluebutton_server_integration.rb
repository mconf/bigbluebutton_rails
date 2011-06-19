file = File.join(File.dirname(__FILE__), "..", "..", "integration_conf.yml")
config = YAML.load_file(file)["server"]

Factory.define :bigbluebutton_server_integration, :parent => :bigbluebutton_server do |s|
  s.sequence(:name) { |n| "Server #{n}" }
  s.url { config["url"] }
  s.salt { config["salt"] }
  s.version { config["version"] }
end
