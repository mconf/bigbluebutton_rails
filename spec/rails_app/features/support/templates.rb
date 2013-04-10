# Verifies the templates (views)
module TemplateHelpers

  # calls the specific methods that verify the template for each page
  def check_template(page_name, options={})
    method = ("check " + page_name).split(" ").join('_').to_sym
    unless self.respond_to?(method)
      raise "Can't find method to check the template for \"#{page_name}\"\n" +
            "Now, go and add the method \"#{method}(options)\" in #{__FILE__}"
    end
    self.send(method, options)
  end

  # servers/new
  def check_new_server(options)
    within(form_selector(bigbluebutton_servers_path, 'post')) do
      check_server_form
    end
  end

  # server/:id/edit
  def check_edit_server(options)
    server = options[:server] || BigbluebuttonServer.last

    within(form_selector(bigbluebutton_server_path(server), 'post')) do
      check_server_form
    end
  end

  # internal form in servers/new and server/:id/edit
  def check_server_form
    has_element("input#bigbluebutton_server_name",
                { :name => 'bigbluebutton_server[name]', :type => 'text' })
    has_element("input#bigbluebutton_server_url",
                { :name => 'bigbluebutton_server[url]', :type => 'text' })
    has_element("input#bigbluebutton_server_salt",
                { :name => 'bigbluebutton_server[salt]', :type => 'text' })
    has_element("input#bigbluebutton_server_version",
                { :name => 'bigbluebutton_server[version]', :type => 'text' })
    has_element("input#bigbluebutton_server_param",
                { :name => 'bigbluebutton_server[param]', :type => 'text' })
    has_element("label", { :for => 'bigbluebutton_server_name' })
    has_element("label", { :for => 'bigbluebutton_server_url' })
    has_element("label", { :for => 'bigbluebutton_server_salt' })
    has_element("label", { :for => 'bigbluebutton_server_version' })
    has_element("label", { :for => 'bigbluebutton_server_param' })
    has_element("input", { :name => 'commit', :type => 'submit' })
  end

  # server/:id/show
  def check_show_server(options)
    server = options[:server] || BigbluebuttonServer.last

    page_has_content(server.name)
    page_has_content(server.url)
    page_has_content(server.salt)
    page_has_content(server.version)
    page_has_content(server.param)
    has_element("a", { :href => edit_bigbluebutton_server_path(server) }) # edit
    has_element("a", { :href => activity_bigbluebutton_server_path(server) }) # activity
    has_element("a", { :href => rooms_bigbluebutton_server_path(server) }) # rooms
    has_element("a", { :href => bigbluebutton_server_path(server), :"data-method" => 'delete' }) # destroy
  end

  # servers/
  def check_servers_index(options)
    servers = options[:severs] || BigbluebuttonServer.all

    has_element("a", { :href => new_bigbluebutton_server_path }) # new server link
    has_element("a", { :href => bigbluebutton_rooms_path }) # rooms list
    n = 1
    servers.each do |server|
      within(make_selector("ul#bbbrails_list>li:nth(#{n})")) do
        # server data
        has_content(server.name)
        has_content(server.url)
        has_content(server.salt)
        has_content(server.version)
        has_content(server.param)
        has_content(server.url)
        # action links
        has_element("a", { :href => bigbluebutton_server_path(server) }) # show
        has_element("a", { :href => rooms_bigbluebutton_server_path(server) }) # rooms
        has_element("a", { :href => activity_bigbluebutton_server_path(server) }) # activity
        has_element("a", { :href => edit_bigbluebutton_server_path(server) }) # edit
        has_element("a", { :href => bigbluebutton_server_path(server), :"data-method" => 'delete' }) # destroy
      end
      n += 1
    end
  end

  # servers/:id/activity
  def check_server_activity_monitor(options)
    server = options[:server] || BigbluebuttonServer.last

    # checks only the 'skeleton', the content depends on the rooms currently running
    # and is not checked here
    within(make_selector("div.bbbrails_countdown")) do
      has_element("span.bbbrails_countdown_value")
      has_element("a.bbbrails_refresh_now",
                  { :href => activity_bigbluebutton_server_path(server) })
    end
    has_element("div#bbbrails_server_activity_meetings")
  end

  # servers/:id/rooms
  def check_server_rooms(options)
    check_rooms_index(options)
  end




  # rooms/new
  def check_new_room(options)
    within(form_selector(bigbluebutton_rooms_path, 'post')) do
      check_room_form
    end
  end

  # room/:id/edit
  def check_edit_room(options)
    room = options[:room] || BigbluebuttonRoom.last

    within(form_selector(bigbluebutton_room_path(room), 'post')) do
      check_room_form
    end
  end

  # internal form in rooms/new and room/:id/edit
  def check_room_form
    has_element("input#bigbluebutton_room_server_id",
                { :name => 'bigbluebutton_room[server_id]', :type => 'text' })
    has_element("input#bigbluebutton_room_name",
                { :name => 'bigbluebutton_room[name]', :type => 'text' })
    has_element("input#bigbluebutton_room_meetingid",
                { :name => 'bigbluebutton_room[meetingid]', :type => 'text' })
    has_element("input#bigbluebutton_room_private",
                { :name => 'bigbluebutton_room[private]', :type => 'checkbox' })
    has_element("input#bigbluebutton_room_attendee_password",
                { :name => 'bigbluebutton_room[attendee_password]', :type => 'password' })
    has_element("input#bigbluebutton_room_moderator_password",
                { :name => 'bigbluebutton_room[moderator_password]', :type => 'password' })
    has_element("input#bigbluebutton_room_welcome_msg",
                { :name => 'bigbluebutton_room[welcome_msg]', :type => 'text' })
    has_element("input#bigbluebutton_room_logout_url",
                { :name => 'bigbluebutton_room[logout_url]', :type => 'text' })
    has_element("input#bigbluebutton_room_dial_number",
                { :name => 'bigbluebutton_room[dial_number]', :type => 'text' })
    has_element("input#bigbluebutton_room_max_participants",
                { :name => 'bigbluebutton_room[max_participants]', :type => 'text' })
    has_element("input#bigbluebutton_room_external",
                { :name => 'bigbluebutton_room[external]', :type => 'checkbox' })
    has_element("input#bigbluebutton_room_param",
                { :name => 'bigbluebutton_room[param]', :type => 'text' })
    has_element("input#bigbluebutton_room_voice_bridge",
                { :name => 'bigbluebutton_room[voice_bridge]', :type => 'text' })
    has_element("label", { :for => 'bigbluebutton_room_name' })
    has_element("label", { :for => 'bigbluebutton_room_meetingid' })
    has_element("label", { :for => 'bigbluebutton_room_private' })
    has_element("label", { :for => 'bigbluebutton_room_attendee_password' })
    has_element("label", { :for => 'bigbluebutton_room_moderator_password' })
    has_element("label", { :for => 'bigbluebutton_room_welcome_msg' })
    has_element("label", { :for => 'bigbluebutton_room_logout_url' })
    has_element("label", { :for => 'bigbluebutton_room_dial_number' })
    has_element("label", { :for => 'bigbluebutton_room_max_participants' })
    has_element("label", { :for => 'bigbluebutton_room_external' })
    has_element("label", { :for => 'bigbluebutton_room_param' })
    has_element("label", { :for => 'bigbluebutton_room_voice_bridge' })
    has_element("input", { :name => 'commit', :type => 'submit' })
  end

  # room/:id/show
  def check_show_room(options)
    room = options[:room] || BigbluebuttonRoom.last

    page_has_content(room.server_id)
    page_has_content(room.name)
    page_has_content(room.meetingid)
    page_has_content(room.private)
    page_has_content(room.attendee_password)
    page_has_content(room.moderator_password)
    page_has_content(room.welcome_msg)
    page_has_content(room.logout_url)
    page_has_content(room.dial_number)
    page_has_content(room.voice_bridge)
    page_has_content(room.max_participants)
    page_has_content(room.external)
    page_has_content(room.param)
    # action links
    has_element("a", { :href => edit_bigbluebutton_room_path(room) }) # edit
    has_element("a", { :href => bigbluebutton_room_path(room) }) # show
    has_element("a", { :href => join_bigbluebutton_room_path(room) }) # join
    has_element("a", { :href => invite_bigbluebutton_room_path(room) }) # invite
    has_element("a", { :href => join_mobile_bigbluebutton_room_path(room) }) # join_mobile
    has_element("a", { :href => end_bigbluebutton_room_path(room) }) # end
    has_element("a", { :href => bigbluebutton_room_path(room), :"data-method" => 'delete' }) # destroy
  end

  # rooms/external
  def check_join_external_room(options)
    room = options[:room] || BigbluebuttonRoom.last

    within(form_selector(external_bigbluebutton_rooms_path, 'post')) do
      has_element("input#server_id", { :name => 'server_id', :type => 'hidden', :value => room.server_id })
      has_element("input#meeting", { :name => 'meeting', :type => 'hidden', :value => room.meetingid })
      has_element("input#user_name", { :name => 'user[name]', :type => 'text' })
      has_element("input#user_password", { :name => 'user[password]', :type => 'password' })
      has_element("label", { :for => 'user_name' })
      has_element("label", { :for => 'user_password' })
      has_element("input", { :name => 'commit', :type => 'submit' })
    end
  end

  # rooms/:id/invite
  def check_invite_room(options)
    room = options[:room] || BigbluebuttonRoom.last

    within(form_selector(join_bigbluebutton_room_path(room), 'post')) do
      has_element("input#user_name", { :name => 'user[name]', :type => 'text' })
      has_element("input#user_password", { :name => 'user[password]', :type => 'password' })
      has_element("label", { :for => 'user_name' })
      has_element("label", { :for => 'user_password' })
      has_element("input", { :name => 'commit', :type => 'submit' })
    end
  end

  # rooms/
  def check_rooms_index(options)
    rooms = options[:rooms] || BigbluebuttonRoom.all

    has_element("a", { :href => new_bigbluebutton_room_path }) # new room link
    has_element("a", { :href => bigbluebutton_servers_path }) # servers list
    n = 1
    rooms.each do |room|
      within(make_selector("ul#bbbrails_list>li:nth(#{n})")) do
        # room data
        has_content(room.server_id) unless room.server.nil?
        has_content(room.name)
        has_content(room.meetingid)
        has_content(room.attendee_password)
        has_content(room.moderator_password)
        has_content(room.logout_url)
        has_content(room.dial_number)
        has_content(room.voice_bridge)
        has_content(room.param)
        # action links
        unless room.server.nil?
          has_element("a", { :href => bigbluebutton_server_path(room.server) }) # show server
        end
        has_element("a", { :href => bigbluebutton_room_path(room) }) # show
        has_element("a", { :href => join_bigbluebutton_room_path(room) }) # join
        has_element("a", { :href => invite_bigbluebutton_room_path(room) }) # invite
        has_element("a", { :href => join_mobile_bigbluebutton_room_path(room) }) # join_mobile
        has_element("a", { :href => edit_bigbluebutton_room_path(room) }) # edit
        has_element("a", { :href => end_bigbluebutton_room_path(room) }) # end
        has_element("a", { :href => bigbluebutton_room_path(room), :"data-method" => 'delete' }) # destroy
      end
      n += 1
    end
  end

  def check_join_room(options) # nothing to check, it only redirects to the BBB client
  end

  # rooms/:id/join_mobile
  def check_mobile_join(options)
    room = options[:room] || BigbluebuttonRoom.last

    url = join_bigbluebutton_room_url(room, :mobile => '1')
    url.gsub!(/http:\/\//i, "bigbluebutton://")
    has_element("a", { :href => url })

    # a soft check that there's an img from chart.googleapis with the qr-code
    img = find(make_selector("img"))
    img[:src].should match(/#{"https://chart.googleapis.com/chart?"}.*/)
  end

end

World(TemplateHelpers)
