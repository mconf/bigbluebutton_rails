module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name, params=nil)
    params = "?" + params.map{ |k,v| "#{k}=#{v}" }.join("&") if params

    case page_name

    when /^home\s?$/
      p = '/'
    when /new server/i
      p = new_bigbluebutton_server_path
    when /new room/i
      p = new_bigbluebutton_server_room_path(@server)
    when /join external room/i
      p = external_bigbluebutton_server_rooms_path(@server)


    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
=begin
      begin
        page_name =~ /^the (.*) page$/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue NoMethodError, ArgumentError
=end
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
#      end
    end

    p += params if params
    p
  end
end

World(NavigationHelpers)
