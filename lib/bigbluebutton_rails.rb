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
  mattr_accessor :room_id_metadata_name
  @@room_id_metadata_name = :'bbbrails-room-id'

  # Finds the BigbluebuttonRoom associated with the recording data
  # in 'data', if any.
  # TODO: if not found, remove the association or keep the old one?
  def self.match_room_recording(data)
    if block_given?
      yield
    else
      param_name = BigbluebuttonRails.room_id_metadata_name
      if data[:metadata] and data[:metadata][param_name]
        BigbluebuttonRoom.find_by_uniqueid(data[:metadata][param_name])
      end
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
