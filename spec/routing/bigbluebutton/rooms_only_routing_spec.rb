require 'spec_helper'

describe ActionController do
  include Shoulda::Matchers::ActionController

  describe "routing with :only => 'rooms'" do

    it {
      {:get => "/only-rooms/bigbluebutton/rooms"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "index")
    }
    it {
      {:get => "/only-rooms/bigbluebutton/rooms/new"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "new")
    }
    it {
      {:get => "/only-rooms/bigbluebutton/rooms/1"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "show", :id => "1")
    }
    it {
      {:get => "/only-rooms/bigbluebutton/rooms/1/edit"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "edit", :id => "1")
    }
    it {
      {:put => "/only-rooms/bigbluebutton/rooms/1"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "update", :id => "1")
    }
    it {
      {:delete => "/only-rooms/bigbluebutton/rooms/1"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "destroy", :id => "1")
    }
    it {
      {:get => "/only-rooms/bigbluebutton/rooms/external"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "external")
    }
    it {
      {:post => "/only-rooms/bigbluebutton/rooms/external"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "external_auth")
    }
    it {
      {:get => "/only-rooms/bigbluebutton/rooms/1/join"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "join", :id => "1")
    }
    it {
      {:get => "/only-rooms/bigbluebutton/rooms/1/join_mobile"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "join_mobile" ,:id => "1")
    }
    it {
      {:get => "/only-rooms/bigbluebutton/rooms/1/running"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "running", :id => "1")
    }
    it {
      {:get => "/only-rooms/bigbluebutton/rooms/1/end"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "end", :id => "1")
    }
    it {
      {:get => "/only-rooms/bigbluebutton/rooms/1/invite"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "invite", :id => "1")
    }
    it {
      {:post => "/only-rooms/bigbluebutton/rooms/1/join"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "auth", :id => "1")
    }

  end

end
