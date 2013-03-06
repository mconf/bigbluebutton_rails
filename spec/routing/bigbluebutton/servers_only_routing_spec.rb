require 'spec_helper'

describe ActionController do
  include Shoulda::Matchers::ActionController

  describe "routing with :only => 'servers'" do

    it {
      {:get => "/only-servers/bigbluebutton/servers"}.
      should route_to(:controller => "bigbluebutton/servers", :action => "index")
    }
    it {
      {:post => "/only-servers/bigbluebutton/servers"}.
      should route_to(:controller => "bigbluebutton/servers", :action => "create")
    }
    it {
      {:get => "/only-servers/bigbluebutton/servers/new"}.
      should route_to(:controller => "bigbluebutton/servers", :action => "new")
    }
    it {
      {:get => "/only-servers/bigbluebutton/servers/1/edit"}.
      should route_to(:controller => "bigbluebutton/servers", :action => "edit", :id => "1")
    }
    it {
      {:get => "/only-servers/bigbluebutton/servers/1"}.
      should route_to(:controller => "bigbluebutton/servers", :action => "show", :id => "1")
    }
    it {
      {:put => "/only-servers/bigbluebutton/servers/1"}.
      should route_to(:controller => "bigbluebutton/servers", :action => "update", :id => "1")
    }
    it {
      {:delete => "/only-servers/bigbluebutton/servers/1"}.
      should route_to(:controller => "bigbluebutton/servers", :action => "destroy", :id => "1")
    }
    it {
      {:get => "/only-servers/bigbluebutton/servers/1/activity"}.
      should route_to(:controller => "bigbluebutton/servers", :action => "activity", :id => "1")
    }

  end

end
