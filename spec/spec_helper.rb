# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require "rails_app/config/environment"
require "rspec/rails"

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "test.com"

Rails.backtrace_cleaner.remove_silencers!

# Configure capybara for integration testing
#require "capybara/rails"
#Capybara.default_driver   = :rack_test
#Capybara.default_selector = :css

require "rails/test_help"
# Run any available migration
#ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {  |f| require f }

# Load Factories
require 'factory_girl'
Dir["#{ File.dirname(__FILE__)}/factories/*.rb"].each { |f| require f }

RSpec.configure do |config|
  # == Mock Framework
  config.mock_with :rspec
end

# For generators
require "generator_spec/test_case"
require "generators/bigbluebutton_rails/install_generator"
