module BigbluebuttonRails

  # Raised when the user is not authorized to join a room
  class RoomAccessDenied < StandardError; end

  # Raised when an action that requires a server is called for a
  # room that does not have a server associated
  class ServerRequired < StandardError; end

end
