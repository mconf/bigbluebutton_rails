# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

if RUBY_VERSION >= "1.9"
  require 'simplecov'
  SimpleCov.start 'rails'
end

require "rails_app/config/environment"
require "rails/test_help"
require "rspec/rails"
require "shoulda-matchers"

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "test.com"

Rails.backtrace_cleaner.remove_silencers!

# Configure capybara for integration testing
#require "capybara/rails"
#Capybara.default_driver   = :rack_test
#Capybara.default_selector = :css

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load Factories
require 'factory_girl'
require 'forgery'
Dir["#{ File.dirname(__FILE__)}/factories/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = true
end

# To test generators
require "generator_spec/test_case"
require "generators/bigbluebutton_rails/install_generator"
require "generators/bigbluebutton_rails/views_generator"
