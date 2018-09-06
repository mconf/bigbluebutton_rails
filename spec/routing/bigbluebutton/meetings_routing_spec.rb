require 'spec_helper'

describe Bigbluebutton::MeetingsController do
  include Shoulda::Matchers::ActionController

  describe "routing", :type => :routing do
    it {
      {:delete => "/meeting/meeting-1"}.
      should route_to(:controller => "bigbluebutton/meetings", :action => "destroy", :id => "meeting-1")
    }
  end
end
