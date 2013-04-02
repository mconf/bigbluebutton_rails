require 'spec_helper'

describe Bigbluebutton::RecordingsController do
  include Shoulda::Matchers::ActionController

  describe "routing" do

    # default and scoped routes
    ['bigbluebutton', 'webconference'].each do |prefix|
      it {
        {:get => "/#{prefix}/recordings"}.
        should route_to(:controller => "bigbluebutton/recordings", :action => "index")
      }
      it {
        {:get => "/#{prefix}/recordings/rec-1/edit"}.
        should route_to(:controller => "bigbluebutton/recordings", :action => "edit", :id => "rec-1")
      }
      it {
        {:get => "/#{prefix}/recordings/rec-1"}.
        should route_to(:controller => "bigbluebutton/recordings", :action => "show", :id => "rec-1")
      }
      it {
        {:put => "/#{prefix}/recordings/rec-1"}.
        should route_to(:controller => "bigbluebutton/recordings", :action => "update", :id => "rec-1")
      }
      it {
        {:delete => "/#{prefix}/recordings/rec-1"}.
        should route_to(:controller => "bigbluebutton/recordings", :action => "destroy", :id => "rec-1")
      }
      it {
        {:get => "/#{prefix}/recordings/rec-1/play?type=any"}.
        should route_to(:controller => "bigbluebutton/recordings", :action => "play", :id => "rec-1")
      }
      it {
        {:post => "/#{prefix}/recordings/rec-1/publish"}.
        should route_to(:controller => "bigbluebutton/recordings", :action => "publish", :id => "rec-1")
      }
      it {
        {:post => "/#{prefix}/recordings/rec-1/unpublish"}.
        should route_to(:controller => "bigbluebutton/recordings", :action => "unpublish", :id => "rec-1")
      }
    end

  end

end
