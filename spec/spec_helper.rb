require 'rubygems'
require 'spork'

#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

if RUBY_VERSION >= "1.9"
  require 'simplecov'
  SimpleCov.start 'rails'
end

require File.expand_path("../rails_app/config/environment", __FILE__)
require "rspec/rails"
require 'shoulda/matchers/integrations/rspec'
require "shoulda-matchers"

# To test generators
require "generator_spec/test_case"
require "generators/bigbluebutton_rails/install_generator"
require "generators/bigbluebutton_rails/views_generator"

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

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
    config.include FactoryGirl::Syntax::Methods
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
end
