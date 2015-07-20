class FeaturesConfig
  cattr_accessor :root   # root of the config file
  cattr_accessor :server # 'pointer' to the server selected

  def self.load
    self.server = nil
    load_file
    select_server
  end

  protected

  def self.load_file
    file = File.join(File.dirname(__FILE__), "..", "config.yml")
    unless File.exists?(file)
      throw Exception.new("Could not load #{file}. Please create it to be able to run the integration tests.")
    end
    self.root = YAML.load_file(file)
  end

  def self.select_server
    if ENV['SERVER']
      unless self.root['servers'].has_key?(ENV['SERVER'])
        throw Exception.new("Server #{ENV['SERVER']} does not exists in your configuration file.")
      end
      server = self.root['servers'][ENV['SERVER']]
    else
      server = self.root['servers'].first[1]
    end
    server['version'] = '0.9' unless server.has_key?('version')
    server['name'] = URI.parse(server['url']).host
    self.server = server
  end
end
