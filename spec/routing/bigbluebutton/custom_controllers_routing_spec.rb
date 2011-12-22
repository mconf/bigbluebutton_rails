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
    it {
      {:get => "/custom/servers/1/activity"}.
      should route_to(:controller => "custom_servers", :action => "activity", :id => "1")
    }

    # custom controllers - rooms
    it {
      {:get => "/custom/rooms"}.
      should route_to(:controller => "custom_rooms", :action => "index")
    }
    it {
      {:get => "/custom/rooms/new"}.
      should route_to(:controller => "custom_rooms", :action => "new")
    }
    it {
      {:get => "/custom/rooms/1"}.
      should route_to(:controller => "custom_rooms", :action => "show", :id => "1")
    }
    it {
      {:get => "/custom/rooms/1/edit"}.
      should route_to(:controller => "custom_rooms", :action => "edit", :id => "1")
    }
    it {
      {:put => "/custom/rooms/1"}.
      should route_to(:controller => "custom_rooms", :action => "update", :id => "1")
    }
    it {
      {:delete => "/custom/rooms/1"}.
      should route_to(:controller => "custom_rooms", :action => "destroy", :id => "1")
    }
    it {
      {:get => "/custom/rooms/external"}.
      should route_to(:controller => "custom_rooms", :action => "external")
    }
    it {
      {:post => "/custom/rooms/external"}.
      should route_to(:controller => "custom_rooms", :action => "external_auth")
    }
    it {
      {:get => "/custom/rooms/1/join"}.
      should route_to(:controller => "custom_rooms", :action => "join", :id => "1")
    }
    it {
      {:get => "/custom/rooms/1/join_mobile"}.
      should route_to(:controller => "custom_rooms", :action => "join_mobile" ,:id => "1")
    }
    it {
      {:get => "/custom/rooms/1/running"}.
      should route_to(:controller => "custom_rooms", :action => "running", :id => "1")
    }
    it {
      {:get => "/custom/rooms/1/end"}.
      should route_to(:controller => "custom_rooms", :action => "end", :id => "1")
    }
    it {
      {:get => "/custom/rooms/1/invite"}.
      should route_to(:controller => "custom_rooms", :action => "invite", :id => "1")
    }
    it {
      {:post => "/custom/rooms/1/join"}.
      should route_to(:controller => "custom_rooms", :action => "auth", :id => "1")
    }

  end

end

