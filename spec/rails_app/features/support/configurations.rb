class FeaturesConfig
  cattr_accessor :server

  def self.load
    self.server = nil
    load_file
    select_server
  end

  def self.load_file
    file = File.join(File.dirname(__FILE__), "..", "integration_conf.yml")
    unless File.exists?(file)
      throw Exception.new("Could not load #{file}. Please create it to be able to run the integration tests.")
    end
    self.server = YAML.load_file(file)
  end

  def self.select_server
    if ENV['SERVER']
      unless self.server['servers'].has_key?(ENV['SERVER'])
        throw Exception.new("Server #{ENV['SERVER']} does not exists in your configuration file.")
      end
      server = self.server['servers'][ENV['SERVER']]
    else
      server = self.server['servers'].first[1]
    end
    server['version'] = '0.7' unless server.has_key?('version')
    server['name'] = URI.parse(server['url']).host
    self.server = server
  end
end
