# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

file = File.join(Rails.root, "..", "integration_conf.yml")
if File.exists? file
  config = YAML.load_file(file)["server"]
  BigbluebuttonServer.create!(config)
end
