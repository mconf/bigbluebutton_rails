class IntegrationConf

  cattr_accessor :config

  def self.load
    @@config = nil
    file = File.join(File.dirname(__FILE__), "..", "..", "integration_conf.yml")
    if File.exists? file
      @@config = YAML.load_file(file)
    else
      puts "* Could not load #{file}. Please create it to be able to run the integration tests."
      exit
    end
  end

end
