module LocalesHelpers

  # translate a string, useful in the feature descriptions, to a key to find
  # the complete message in the locale files
  def message_to_locale_key(msg)
    case msg.downcase
    when /the meeting is not running/
      key = 'bigbluebutton_rails.rooms.errors.auth.not_running'
    when /authentication failure/
      key = 'bigbluebutton_rails.rooms.errors.auth.failure'
    else
      key = ''
    end
  end

end

World(LocalesHelpers)
