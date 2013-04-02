require 'spec_helper'

describe ActionController do
  include Shoulda::Matchers::ActionController

  describe "routing with :only => 'recordings'" do

    it {
      {:get => "/only-recordings/bigbluebutton/recordings"}.
      should route_to(:controller => "bigbluebutton/recordings", :action => "index")
    }
    it {
      {:get => "/only-recordings/bigbluebutton/recordings/rec-1/edit"}.
      should route_to(:controller => "bigbluebutton/recordings", :action => "edit", :id => "rec-1")
    }
    it {
      {:get => "/only-recordings/bigbluebutton/recordings/rec-1"}.
      should route_to(:controller => "bigbluebutton/recordings", :action => "show", :id => "rec-1")
    }
    it {
      {:put => "/only-recordings/bigbluebutton/recordings/rec-1"}.
      should route_to(:controller => "bigbluebutton/recordings", :action => "update", :id => "rec-1")
    }
    it {
      {:delete => "/only-recordings/bigbluebutton/recordings/rec-1"}.
      should route_to(:controller => "bigbluebutton/recordings", :action => "destroy", :id => "rec-1")
    }
    it {
      {:get => "/only-recordings/bigbluebutton/recordings/rec-1/play?type=any"}.
      should route_to(:controller => "bigbluebutton/recordings", :action => "play", :id => "rec-1")
    }
    it {
      {:post => "/only-recordings/bigbluebutton/recordings/rec-1/publish"}.
      should route_to(:controller => "bigbluebutton/recordings", :action => "publish", :id => "rec-1")
    }
    it {
      {:post => "/only-recordings/bigbluebutton/recordings/rec-1/unpublish"}.
      should route_to(:controller => "bigbluebutton/recordings", :action => "unpublish", :id => "rec-1")
    }

  end

end
