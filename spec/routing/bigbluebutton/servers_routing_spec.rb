require 'spec_helper'

describe Bigbluebutton::ServersController do
  include Shoulda::Matchers::ActionController

  describe "routing" do

    # normal and scoped routes
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
        {:get => "/#{prefix}/servers/1/edit"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "edit", :id => "1")
      }
      it {
        {:get => "/#{prefix}/servers/1"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "show", :id => "1")
      }
      it {
        {:put => "/#{prefix}/servers/1"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "update", :id => "1")
      }
      it {
        {:delete => "/#{prefix}/servers/1"}.
        should route_to(:controller => "bigbluebutton/servers", :action => "destroy", :id => "1")
      }
    end

  end

end

