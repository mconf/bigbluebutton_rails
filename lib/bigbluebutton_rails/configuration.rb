module BigbluebuttonRails
  class Configuration
    attr_accessor :guest_support
    attr_accessor :controllers
    attr_accessor :routing_scope
    attr_accessor :metadata_room_id
    attr_accessor :metadata_user_id
    attr_accessor :metadata_user_name
    attr_accessor :metadata_invitation_url
    attr_accessor :metadata_invalid_keys
    attr_accessor :user_attr_name
    attr_accessor :user_attr_id
    attr_accessor :use_local_voice_bridges
    attr_accessor :api_secret

    # methods
    attr_accessor :select_server
    attr_accessor :match_room_recording
    attr_accessor :get_invitation_url
    attr_accessor :get_create_options
    attr_accessor :get_join_options
    attr_accessor :playback_url_authentication

    def initialize
      @controllers = {
        servers: 'bigbluebutton/servers',
        rooms: 'bigbluebutton/rooms',
        recordings: 'bigbluebutton/recordings',
        playback_types: 'bigbluebutton/playback_types'
      }
      @routing_scope = 'bigbluebutton'

      @metadata_room_id        = :'bbbrails-room-id'
      @metadata_user_id        = :'bbbrails-user-id'
      @metadata_user_name      = :'bbbrails-user-name'
      @metadata_invitation_url = :'invitation-url'
      @metadata_invalid_keys =
        [ @metadata_room_id, @metadata_user_id,
          @metadata_user_name, @metadata_invitation_url ]

      @user_attr_name = :'name'
      @user_attr_id   = :'id'
      @use_local_voice_bridges = false
      @guest_support = false
      # Flag to use authentication on playback url
      @playback_url_authentication = false

      # How to find the room of a recording using the `data` returned by
      # a `getRecordings`.
      @match_room_recording = Proc.new do |data, *args|
        BigbluebuttonRoom.find_by_meetingid(data[:meetingid])
      end

      # Default method to return the invitation URL of a room. By default
      # returns nil (disable the feature).
      @get_invitation_url = Proc.new{ |room| nil }

      # Define this method to return extra parameters to be passed to a `create` call.
      # `user` is the user creating the meeting, if any.
      @get_create_options = Proc.new{ |room, user| nil }

      # Define this method to return extra parameters to be passed to a `join` call.
      # `user` is the user joining the meeting, if any.
      @get_join_options = Proc.new{ |room, user| nil }

      # Selects a server to be used by `room` whenever it needs to make API calls.
      # By default, if no servers are available an exception is raised.
      #
      # This method can be overwritten to change the way the server is selected
      # before a room is used. `api_method` contains the API method that is being
      # called. Any server returned here will be used. It *must* return a server,
      # otherwise the API calls will fail and the code will probably break.
      #
      # One good example is to always select a new server when a meeting is being
      # created (in case `api_method` is `:create`), making this a simple load
      # balancing tool that can work well in simple cases.
      @select_server = Proc.new do |room, api_method=nil|
        room.select_server(api_method)
      end

      # Secret used to authenticate API calls. API calls received are expected to set
      # the HTTP header "Authorization" with a value "Bearer 123123123123", where
      # "123123123123" is the secret set in `api_secret`.
      # Notice that this header has the secret in clear text in the HTTP request, so
      # only use it if your application is hosted with HTTPS.
      # Set it to an empty string to disable authentication. Set it to nil to deny all
      # requests (disable the API).
      @api_secret = nil
    end

    def set_controllers(options)
      unless options.nil? || options.empty?
        @controllers.merge!(options).slice!(:servers, :rooms, :recordings, :playback_types)
      end
    end

  end
end
