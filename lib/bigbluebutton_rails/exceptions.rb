module BigbluebuttonRails

  # Raised when the user is not authorized to join a room
  class RoomAccessDenied < StandardError; end

  # Raised when an action that requires a server is called for a
  # room that does not have a server associated
  class ServerRequired < StandardError; end

  # To help create responses for API errors
  class APIError < StandardError
    def initialize(msg, code=500, title=nil)
      @title = title || msg
      @code = code
      super(msg)
    end

    def code
      @code
    end

    def title
      @title
    end
  end

end
