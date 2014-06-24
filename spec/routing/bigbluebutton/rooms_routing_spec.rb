require 'spec_helper'

describe Bigbluebutton::RoomsController do
  include Shoulda::Matchers::ActionController

  describe "routing" do

    # default and scoped routes
    ['bigbluebutton', 'webconference'].each do |prefix|

      it {
        {:get => "/#{prefix}/rooms"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "index")
      }
      it {
        {:get => "/#{prefix}/rooms/new"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "new")
      }
      it {
        {:get => "/#{prefix}/rooms/room-1"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "show", :id => "room-1")
      }
      it {
        {:get => "/#{prefix}/rooms/room-1/edit"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "edit", :id => "room-1")
      }
      it {
        {:put => "/#{prefix}/rooms/room-1"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "update", :id => "room-1")
      }
      it {
        {:delete => "/#{prefix}/rooms/room-1"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "destroy", :id => "room-1")
      }
      it {
        {:get => "/#{prefix}/rooms/room-1/join"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "join", :id => "room-1")
      }
      it {
        {:get => "/#{prefix}/rooms/room-1/join_mobile"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "join_mobile" ,:id => "room-1")
      }
      it {
        {:get => "/#{prefix}/rooms/room-1/running"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "running", :id => "room-1")
      }
      it {
        {:get => "/#{prefix}/rooms/room-1/end"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "end", :id => "room-1")
      }
      it {
        {:get => "/#{prefix}/rooms/room-1/invite"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "invite", :id => "room-1")
      }
      it {
        {:post => "/#{prefix}/rooms/room-1/join"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "join", :id => "room-1")
      }
      it {
        {:post => "/#{prefix}/rooms/room-1/fetch_recordings"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "fetch_recordings", :id => "room-1")
      }
      it {
        {:get => "/#{prefix}/rooms/room-1/recordings"}.
        should route_to(:controller => "bigbluebutton/rooms", :action => "recordings", :id => "room-1")
      }

    end

    # room matchers inside users
    it {
      { :get => "/users/1/rooms" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "index",
                      :user_id => "1")
    }
    it {
      { :get => "/users/1/rooms/new" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "new",
                      :user_id => "1")
    }
    it {
      { :get => "/users/1/rooms/room-1" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "show",
                      :user_id => "1", :id => "room-1")
    }
    it {
      { :get => "/users/1/rooms/room-1/edit" }.
        should route_to(:controller => "bigbluebutton/rooms", :action => "edit",
                        :user_id => "1", :id => "room-1")
    }
    it {
      { :put => "/users/1/rooms/room-1" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "update",
                      :user_id => "1", :id => "room-1")
    }
    it {
      { :delete => "/users/1/rooms/room-1" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "destroy",
                      :user_id => "1", :id => "room-1")
    }
    it {
      { :get => "/users/1/rooms/room-1/join" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "join",
                      :user_id => "1", :id => "room-1")
    }
    it {
      { :get => "/users/1/rooms/room-1/join_mobile" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "join_mobile",
                      :user_id => "1", :id => "room-1")
    }
    it {
      { :get => "/users/1/rooms/room-1/running" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "running",
                      :user_id => "1", :id => "room-1")
    }
    it {
      { :get => "/users/1/rooms/room-1/end" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "end",
                      :user_id => "1", :id => "room-1")
    }
    it {
      { :get => "/users/1/rooms/room-1/invite" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "invite",
                      :user_id => "1", :id => "room-1")
    }
    it {
      { :post => "/users/1/rooms/room-1/join" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "join",
                      :user_id => "1", :id => "room-1")
    }
    it {
      {:post => "/users/1/rooms/room-1/fetch_recordings"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "fetch_recordings",
                      :user_id => "1", :id => "room-1")
    }
    it {
      {:get => "/users/1/rooms/room-1/recordings"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "recordings",
                      :user_id => "1", :id => "room-1")
    }

    # room matchers inside users/spaces
    it {
      { :get => "/users/1/spaces/2/rooms" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "index",
                      :user_id => "1", :space_id => "2")
    }
    it {
      { :get => "/users/1/spaces/2/rooms/new" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "new",
                      :user_id => "1", :space_id => "2")
    }
    it {
      { :get => "/users/1/spaces/2/rooms/room-1" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "show",
                      :user_id => "1", :space_id => "2", :id => "room-1")
    }
    it {
      { :get => "/users/1/spaces/2/rooms/room-1/edit" }.
        should route_to(:controller => "bigbluebutton/rooms", :action => "edit",
                        :user_id => "1", :space_id => "2", :id => "room-1")
    }
    it {
      { :put => "/users/1/spaces/2/rooms/room-1" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "update",
                      :user_id => "1", :space_id => "2", :id => "room-1")
    }
    it {
      { :delete => "/users/1/spaces/2/rooms/room-1" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "destroy",
                      :user_id => "1", :space_id => "2", :id => "room-1")
    }
    it {
      { :get => "/users/1/spaces/2/rooms/room-1/join" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "join",
                      :user_id => "1", :space_id => "2", :id => "room-1")
    }
    it {
      { :get => "/users/1/spaces/2/rooms/room-1/join_mobile" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "join_mobile",
                      :user_id => "1", :space_id => "2", :id => "room-1")
    }
    it {
      { :get => "/users/1/spaces/2/rooms/room-1/running" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "running",
                      :user_id => "1", :space_id => "2", :id => "room-1")
    }
    it {
      { :get => "/users/1/spaces/2/rooms/room-1/end" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "end",
                      :user_id => "1", :space_id => "2", :id => "room-1")
    }
    it {
      { :get => "/users/1/spaces/2/rooms/room-1/invite" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "invite",
                      :user_id => "1", :space_id => "2", :id => "room-1")
    }
    it {
      { :post => "/users/1/spaces/2/rooms/room-1/join" }.
      should route_to(:controller => "bigbluebutton/rooms", :action => "join",
                      :user_id => "1", :space_id => "2", :id => "room-1")
    }
    it {
      {:post => "/users/1/spaces/2/rooms/room-1/fetch_recordings"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "fetch_recordings",
                      :user_id => "1", :space_id => "2", :id => "room-1")
    }
    it {
      {:get => "/users/1/spaces/2/rooms/room-1/recordings"}.
      should route_to(:controller => "bigbluebutton/rooms", :action => "recordings",
                      :user_id => "1", :space_id => "2", :id => "room-1")
    }
 end

end
