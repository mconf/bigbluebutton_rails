# require 'capybara-webkit'
require 'capybara/mechanize/cucumber'

# Load the environment in the gem folders, not in the rails_app
# Load the factories in the gem spec/factories folder
require 'factory_girl'
require 'forgery'
Dir["#{ File.dirname(__FILE__)}/../../../factories/*.rb"].each { |f| require f }

# Found at: http://www.emmanueloga.com/2011/07/26/taming-a-capybara.html
# Big Fat Hack (TM) so the ActiveRecord connections are shared across threads.
# This is a variation of a hack you can find all over the web to make
# capybara usable without having to switch to non transactional
# fixtures.
# http://groups.google.com/group/ruby-capybara/browse_thread/thread/248e89ae2acbf603/e5da9e9bfac733e0
# https://groups.google.com/forum/#!msg/ruby-capybara/JI6JrirL9gM/R6YiXj4gi_UJ
# Thread.main[:activerecord_connection] = ActiveRecord::Base.retrieve_connection
# def (ActiveRecord::Base).connection
#   Thread.main[:activerecord_connection]
# end
