require 'spec_helper'

describe ActionController do
  include Shoulda::Matchers::ActionController

  describe "routing" do

    # custom controllers - servers
    it {
      {:get => "/custom/servers"}.
      should route_to(:controller => "custom_servers", :action => "index")
    }
    it {
      {:post => "/custom/servers"}.
      should route_to(:controller => "custom_servers", :action => "create")
    }
    it {
      {:get => "/custom/servers/new"}.
      should route_to(:controller => "custom_servers", :action => "new")
    }
    it {
      {:get => "/custom/servers/1/edit"}.
      should route_to(:controller => "custom_servers", :action => "edit", :id => "1")
    }
    it {
      {:get => "/custom/servers/1"}.
      should route_to(:controller => "custom_servers", :action => "show", :id => "1")
    }
    it {
      {:put => "/custom/servers/1"}.
      should route_to(:controller => "custom_servers", :action => "update", :id => "1")
    }
    it {
      {:delete => "/custom/servers/1"}.
      should route_to(:controller => "custom_servers", :action => "destroy", :id => "1")
    }

    # custom controllers - rooms
    it {
      {:get => "/custom/servers/1/rooms"}.
      should route_to(:controller => "custom_rooms", :action => "index", :server_id => "1")
    }
    it {
      {:get => "/custom/servers/1/rooms/new"}.
      should route_to(:controller => "custom_rooms", :action => "new", :server_id => "1")
    }
    it {
      {:get => "/custom/servers/1/rooms/1/edit"}.
      should route_to(:controller => "custom_rooms", :action => "edit", :server_id => "1", :id => "1")
    }
    it {
      {:get => "/custom/servers/1/rooms/1"}.
      should route_to(:controller => "custom_rooms", :action => "show", :server_id => "1", :id => "1")
    }
    it {
      {:put => "/custom/servers/1/rooms/1"}.
      should route_to(:controller => "custom_rooms", :action => "update", :server_id => "1", :id => "1")
    }
    it {
      {:delete => "/custom/servers/1/rooms/1"}.
      should route_to(:controller => "custom_rooms", :action => "destroy", :server_id => "1", :id => "1")
    }
    it {
      {:get => "/custom/servers/1/rooms/1/join"}.
      should route_to(:controller => "custom_rooms", :action => "join", :server_id => "1", :id => "1")
    }
    it {
      {:get => "/custom/servers/1/rooms/1/running"}.
      should route_to(:controller => "custom_rooms", :action => "running", :server_id => "1", :id => "1")
    }
    it {
      {:get => "/custom/servers/1/rooms/1/end"}.
      should route_to(:controller => "custom_rooms", :action => "end", :server_id => "1", :id => "1")
    }
    it {
      {:get => "/custom/servers/1/rooms/1/invite"}.
      should route_to(:controller => "custom_rooms", :action => "invite", :server_id => "1", :id => "1")
    }
    it {
      {:post => "/custom/servers/1/rooms/1/join"}.
      should route_to(:controller => "custom_rooms", :action => "auth", :server_id => "1", :id => "1")
    }

  end

end

