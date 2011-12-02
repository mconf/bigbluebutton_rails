module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name, params=nil)
    params = "?" + params.map{ |k,v| "#{k}=#{CGI::escape(v)}" }.join("&") if params

    case page_name

    when /^home\s?$/
      p = '/'
    when /new server/i
      p = new_bigbluebutton_server_path
    when /servers index/i, /create server/i
      p = bigbluebutton_servers_path
    when /show server/i
      p = bigbluebutton_server_path(@server)
    when /edit server/i
      p = edit_bigbluebutton_server_path(@server)
    when /update server/i
      p = bigbluebutton_server_path(@server)
    when /new room/i
      p = new_bigbluebutton_server_room_path(@server)
    when /rooms index/i, /create room/i
      p = bigbluebutton_server_rooms_path(@server)
    when /join external room/i
      p = external_bigbluebutton_server_rooms_path(@server)
    when /show room/i
      p = bigbluebutton_server_room_path(@server, @room)
    when /edit room/i
      p = edit_bigbluebutton_server_room_path(@server, @room)
    when /update room/i
      p = bigbluebutton_server_room_path(@server, @room)
    when /join room/i
      p = join_bigbluebutton_server_room_path(@server, @room)
    when /invite room/i
      p = invite_bigbluebutton_server_room_path(@server, @room)

    else
      begin
        page_name =~ /^the (.*) page$/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue NoMethodError, ArgumentError
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end

    p += params if params
    p
  end
end

World(NavigationHelpers)
