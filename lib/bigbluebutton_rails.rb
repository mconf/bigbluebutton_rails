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

  # Name of the metadata parameter that will contain the room's ID
  # when a room is created. Used to match the room of a recording when
  # recordings are fetched from the DB.
  # Has to be a symbol!
  mattr_accessor :metadata_room_id
  @@metadata_room_id = :'bbbrails-room-id'

  # Name of the metadata parameter that will contain the user's ID
  # when a room is created.
  # Has to be a symbol!
  mattr_accessor :metadata_user_id
  @@metadata_user_id = :'bbbrails-user-id'

  # Name of the metadata parameter that will contain the user's name
  # when a room is created.
  # Has to be a symbol!
  mattr_accessor :metadata_user_name
  @@metadata_user_name = :'bbbrails-user-name'

  # List of invalid metadata keys. Invalid keys are usually keys that are
  # used by the gem and by the application. The application using this gem
  # can add items to this list as well.
  # All values added can be symbols or strings.
  mattr_accessor :metadata_invalid_keys
  @@metadata_invalid_keys =
    [ @@metadata_room_id,
      @@metadata_user_id,
      @@metadata_user_name ]

  # Finds the BigbluebuttonRoom associated with the recording data in 'data', if any.
  # TODO: if not found, remove the association or keep the old one?
  def self.match_room_recording(data)
    if block_given?
      yield
    else
      BigbluebuttonRoom.find_by_meetingid(data[:meetingid])
    end
  end

  def self.set_controllers(options)
    unless options.nil?
      @@controllers.merge!(options).slice!(:servers, :rooms, :recordings)
    end
  end

  # Default way to setup the gem.
  def self.setup
    yield self
  end

end
