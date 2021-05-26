require 'spec_helper'

describe Bigbluebutton::MeetingsController do
  include Shoulda::Matchers::ActionController

  describe "routing", :type => :routing do
		['bigbluebutton', 'webconference'].each do |prefix|
	    it {
	      {:delete => "/#{prefix}/meetings/1"}.
	      should route_to(:controller => "bigbluebutton/meetings", :action => "destroy", :id => "1")
	    }
	  end
	end
end