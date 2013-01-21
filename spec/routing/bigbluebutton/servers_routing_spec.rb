require 'spec_helper'

describe Bigbluebutton::ServersController do
  include Shoulda::Matchers::ActionController

  describe "routing" do

    # default and scoped routes
    ['bigbluebutton', 'webconference'].each do |prefix|
      it {
        {:get => "/#{prefix}/servers"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "index")
      }
      it {
        {:post => "/#{prefix}/servers"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "create")
      }
      it {
        {:get => "/#{prefix}/servers/new"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "new")
      }
      it {
        {:get => "/#{prefix}/servers/server-1/edit"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "edit", :id => "server-1")
      }
      it {
        {:get => "/#{prefix}/servers/server-1"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "show", :id => "server-1")
      }
      it {
        {:put => "/#{prefix}/servers/server-1"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "update", :id => "server-1")
      }
      it {
        {:delete => "/#{prefix}/servers/server-1"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "destroy", :id => "server-1")
      }
      it {
        {:get => "/#{prefix}/servers/server-1/activity"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "activity", :id => "server-1")
      }
      it {
        {:get => "/#{prefix}/servers/server-1/rooms"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "rooms", :id => "server-1")
      }
      it {
        {:get => "/#{prefix}/servers/server-1/recordings"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "recordings", :id => "server-1")
      }
      it {
        {:post => "/#{prefix}/servers/server-1/publish_recordings"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "publish_recordings", :id => "server-1")
      }
      it {
        {:post => "/#{prefix}/servers/server-1/unpublish_recordings"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "unpublish_recordings", :id => "server-1")
      }
      it {
        {:post => "/#{prefix}/servers/server-1/fetch_recordings"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "fetch_recordings", :id => "server-1")
      }
    end

  end

end
