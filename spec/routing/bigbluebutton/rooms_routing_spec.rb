require 'spec_helper'

describe Bigbluebutton::RoomsController do
  include Shoulda::Matchers::ActionController

  describe "routing" do

    # normal and scoped routes
    ['bigbluebutton', 'webconference'].each do |prefix|

      it {
        {:get => "/#{prefix}/servers/1/rooms"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "index", :server_id => "1")
      }
      it {
        {:get => "/#{prefix}/servers/1/rooms/new"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "new", :server_id => "1")
      }
      it {
        {:get => "/#{prefix}/servers/1/rooms/1/edit"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "edit", :server_id => "1", :id => "1")
      }
      it {
        {:get => "/#{prefix}/servers/1/rooms/1"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "show", :server_id => "1", :id => "1")
      }
      it {
        {:put => "/#{prefix}/servers/1/rooms/1"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "update", :server_id => "1", :id => "1")
      }
      it {
        {:delete => "/#{prefix}/servers/1/rooms/1"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "destroy", :server_id => "1", :id => "1")
      }
      it {
        {:get => "/#{prefix}/servers/1/rooms/1/join"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "join", :server_id => "1", :id => "1")
      }
      it {
        {:get => "/#{prefix}/servers/1/rooms/1/join_mobile"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "join_mobile", :server_id => "1", :id => "1")
      }
      it {
        {:get => "/#{prefix}/servers/1/rooms/1/running"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "running", :server_id => "1", :id => "1")
      }
      it {
        {:get => "/#{prefix}/servers/1/rooms/1/end"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "end", :server_id => "1", :id => "1")
      }
      it {
        {:get => "/#{prefix}/servers/1/rooms/1/invite"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "invite", :server_id => "1", :id => "1")
      }
      it {
        {:post => "/#{prefix}/servers/1/rooms/1/join"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "auth", :server_id => "1", :id => "1")
      }

    end

    # room matchers inside users
    it {
      should route(:get, "/users/1/room/1").
        to(:action => :show, :user_id => "1", :id => "1")
    }
    it {
      should route(:get, "/users/1/room/1/join").
        to(:action => :join, :user_id => "1", :id => "1")
    }
    it {
      should route(:get, "/users/1/room/1/join_mobile").
        to(:action => :join_mobile, :user_id => "1", :id => "1")
    }
    it {
      should route(:get, "/users/1/room/1/running").
        to(:action => :running, :user_id => "1", :id => "1")
    }
    it {
      should route(:get, "/users/1/room/1/end").
        to(:action => :end, :user_id => "1", :id => "1")
    }
    it {
      should route(:get, "/users/1/room/1/invite").
        to(:action => :invite, :user_id => "1", :id => "1")
    }
    it {
      should route(:post, "/users/1/room/1/join").
        to(:action => :auth, :user_id => "1", :id => "1")
    }

    # room matchers inside users/spaces
    # FIXME shoulda-matcher is not working here, why?
    it {
      { :get => "/users/1/spaces/2/room/3" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "show", :user_id => "1", :space_id => "2", :id => "3")
    }
    it {
      { :get => "/users/1/spaces/2/room/3/join" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "join", :user_id => "1", :space_id => "2", :id => "3")
    }
    it {
      { :get => "/users/1/spaces/2/room/3/join_mobile" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "join_mobile", :user_id => "1", :space_id => "2", :id => "3")
    }
    it {
      { :get => "/users/1/spaces/2/room/3/running" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "running", :user_id => "1", :space_id => "2", :id => "3")
    }
    it {
      { :get => "/users/1/spaces/2/room/3/end" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "end", :user_id => "1", :space_id => "2", :id => "3")
    }
    it {
      { :get => "/users/1/spaces/2/room/3/invite" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "invite", :user_id => "1", :space_id => "2", :id => "3")
    }
    it {
      { :post => "/users/1/spaces/2/room/3/join" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "auth", :user_id => "1", :space_id => "2", :id => "3")
    }
 end

end

