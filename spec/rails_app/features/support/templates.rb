# Verifies the templates (views)
module TemplateHelpers

  # calls the specific methods that verify the template for each page
  def check_template(page_name)
    begin
      method = ("check " + page_name).split(" ").join('_').to_sym
      self.send(method)
    rescue NoMethodError, ArgumentError
      raise "Can't find method to check the template for \"#{page_name}\"\n" +
            "Now, go and add the method \"#{method}\" in #{__FILE__}"
    end
  end

  # servers/new
  def check_new_server
    within(form_selector(bigbluebutton_servers_path, 'post')) do
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
  end

  # servers/new
  def check_new_room
    within(form_selector(bigbluebutton_server_rooms_path(@server), 'post')) do
      has_element("input#bigbluebutton_room_name",
                  { :name => 'bigbluebutton_room[name]', :type => 'text' })
      has_element("input#bigbluebutton_room_meetingid",
                  { :name => 'bigbluebutton_room[meetingid]', :type => 'text' })
      has_element("input#bigbluebutton_room_randomize_meetingid",
                  { :name => 'bigbluebutton_room[randomize_meetingid]', :type => 'checkbox' })
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
      has_element("label", { :for => 'bigbluebutton_room_randomize_meetingid' })
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
  end

  # room/:id/show
  def check_show_room
    room = BigbluebuttonRoom.last
    page_has_content(room.name)
    page_has_content(room.meetingid)
    page_has_content(room.randomize_meetingid)
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
  end

  # server/:id/show
  def check_show_server
    server = BigbluebuttonServer.last
    page_has_content(server.name)
    page_has_content(server.url)
    page_has_content(server.salt)
    page_has_content(server.version)
    page_has_content(server.param)
  end

  # rooms/external
  def check_join_external_room
    within(form_selector(external_bigbluebutton_server_rooms_path(@server), 'post')) do
      has_element("input#meeting", { :name => 'meeting', :type => 'hidden', :value => @room.meetingid })
      has_element("input#user_name", { :name => 'user[name]', :type => 'text' })
      has_element("input#user_password", { :name => 'user[password]', :type => 'password' })
      has_element("label", { :for => 'user_name' })
      has_element("label", { :for => 'user_password' })
    end
  end

  # rooms/
  def check_rooms_index
    has_element("a", { :href => new_bigbluebutton_server_room_path(@server) }) # new room link
    n = 1
    BigbluebuttonRoom.all.each do |room|
      within(make_selector("ul#bbbrails_rooms_list>li:nth(#{n})")) do
        # room data
        has_content(room.name)
        has_content(room.meetingid)
        has_content(room.attendee_password)
        has_content(room.moderator_password)
        has_content(room.logout_url)
        has_content(room.dial_number)
        has_content(room.voice_bridge)
        has_content(room.param)
        # action links
        has_element("a", { :href => bigbluebutton_server_room_path(@server, room) }) # show
        has_element("a", { :href => join_bigbluebutton_server_room_path(@server, room) }) # join
        has_element("a", { :href => invite_bigbluebutton_server_room_path(@server, room) }) # invite
        has_element("a", { :href => join_mobile_bigbluebutton_server_room_path(@server, room) }) # join_mobile
        has_element("a", { :href => edit_bigbluebutton_server_room_path(@server, room) }) # edit
        has_element("a", { :href => end_bigbluebutton_server_room_path(@server, room) }) # end
        has_element("a", { :href => bigbluebutton_server_room_path(@server, room), :"data-method" => 'delete' }) # destroy
      end
      n += 1
    end
  end

  # servers/
  def check_servers_index
    has_element("a", { :href => new_bigbluebutton_server_path }) # new server link
    n = 1
    BigbluebuttonServer.all.each do |server|
      within(make_selector("ul#bbbrails_servers_list>li:nth(#{n})")) do
        # server data
        has_content(server.name)
        has_content(server.url)
        has_content(server.salt)
        has_content(server.version)
        has_content(server.param)
        has_content(server.url)
        # action links
        has_element("a", { :href => bigbluebutton_server_path(server) }) # show
        has_element("a", { :href => bigbluebutton_server_rooms_path(server) }) # index
        has_element("a", { :href => activity_bigbluebutton_server_path(server) }) # activity
        has_element("a", { :href => edit_bigbluebutton_server_path(server) }) # edit
        has_element("a", { :href => bigbluebutton_server_path(server), :"data-method" => 'delete' }) # destroy
      end
      n += 1
    end
  end

end

World(TemplateHelpers)
