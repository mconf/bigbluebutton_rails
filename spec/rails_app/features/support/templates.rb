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
  # TODO check <label>'s
  # TODO check ids?
  def check_new_server
    within(form_selector(bigbluebutton_servers_path, 'post')) do
      has_element("input", { :name => 'bigbluebutton_server[name]', :type => 'text' })
      has_element("input", { :name => 'bigbluebutton_server[url]', :type => 'text' })
      has_element("input", { :name => 'bigbluebutton_server[salt]', :type => 'text' })
      has_element("input", { :name => 'bigbluebutton_server[version]', :type => 'text' })
      has_element("input", { :name => 'bigbluebutton_server[param]', :type => 'text' })
      has_element("input", { :name => 'commit', :type => 'submit' })
    end
  end

  # rooms/external
  # TODO check <label>'s
  # TODO check ids?
  def check_join_external_room
    within(form_selector(external_bigbluebutton_server_rooms_path(@server), 'post')) do
      has_element("input", { :name => 'meeting', :type => 'hidden', :value => @room.meetingid })
      has_element("input", { :name => 'user[name]', :type => 'text' })
      has_element("input", { :name => 'user[password]', :type => 'password' })
    end
  end
end

World(TemplateHelpers)
