# Load the environment in the gem folders, not in the rails_app

# Load the factories in the gem spec/factories folder
require 'factory_girl'
require 'forgery'
Dir["#{ File.dirname(__FILE__)}/../../../factories/*.rb"].each { |f| require f }
