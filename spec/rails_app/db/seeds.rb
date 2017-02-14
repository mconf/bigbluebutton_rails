# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

file = File.join(Rails.root, "features", "config.yml")
if File.exists?(file)
  config = YAML.load_file(file)

  if ENV['SERVER']
    unless config['servers'].has_key?(ENV['SERVER'])
      throw Exception.new("Server #{ENV['SERVER']} does not exists in your configuration file.")
    end
    server = config['servers'][ENV['SERVER']]
  else
    server = config['servers'][config['servers'].keys.first]
  end
  server['version'] = '1.0' unless server.has_key?('version')
  server['name'] = URI.parse(server['url']).host

  BigbluebuttonServer.create!(server)
end
