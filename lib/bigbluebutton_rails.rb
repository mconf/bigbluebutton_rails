require 'rails'

require 'classes/bigbluebutton_attendee'

module BigbluebuttonRails
  require 'bigbluebutton_rails/rails'
  require 'bigbluebutton_rails/utils'
  require 'bigbluebutton_rails/controller_methods'
  require 'bigbluebutton_rails/rails/routes'
  require 'bigbluebutton_rails/exceptions'

  # Default controllers to generate the routes
  mattr_accessor :controllers
  @@controllers = {
    :servers => 'bigbluebutton/servers',
    :rooms => 'bigbluebutton/rooms',
    :recordings => 'bigbluebutton/recordings'
  }

  # Default scope for routes
  mattr_accessor :routing_scope
  @@routing_scope = 'bigbluebutton'

  def self.set_controllers(options)
    @@controllers.merge!(options).slice!(:servers, :rooms) unless options.nil?
  end

end
