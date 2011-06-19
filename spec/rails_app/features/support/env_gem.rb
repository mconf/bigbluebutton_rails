# Load the environment to test the gem bigbluebutton_rails using cucumber

# Load the factories in the gem spec/factories folder
require 'factory_girl'
require 'forgery'
Dir["#{ File.dirname(__FILE__)}/../../../factories/**/*.rb"].each { |f| require f }
