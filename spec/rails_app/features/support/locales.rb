module LocalesHelpers

  # translate a string, useful in the feature descriptions, to a key to find
  # the complete message in the locale files
  def message_to_locale_key(msg)
    case msg.downcase
    when /the meeting is not running/
      key = 'bigbluebutton_rails.rooms.errors.join.not_running'
    when /authentication failure/
      key = 'bigbluebutton_rails.rooms.errors.join.failure'
    when /you don't have permissions to start this meeting/
      key = 'bigbluebutton_rails.rooms.errors.join.cannot_create'
    else
      key = ''
    end
  end

end

World(LocalesHelpers)
