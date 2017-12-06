require 'rails'
require 'browser'
require 'resque'
require 'resque-scheduler'

require 'bigbluebutton_rails/rails'
require 'bigbluebutton_rails/configuration'
require 'bigbluebutton_rails/utils'
require 'bigbluebutton_rails/controller_methods'
require 'bigbluebutton_rails/internal_controller_methods'
require 'bigbluebutton_rails/api_controller_methods'
require 'bigbluebutton_rails/background_tasks'
require 'bigbluebutton_rails/rails/routes'
require 'bigbluebutton_rails/exceptions'
require 'bigbluebutton_rails/dial_number'

module BigbluebuttonRails
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
