require 'spec_helper'

describe Bigbluebutton::RoomsController do
  include Shoulda::Matchers::ActionController

  describe "routing" do
    it {
      should route(:get, "/bigbluebutton/servers/1/rooms").
        to(:action => :index, :server_id => "1")
    }
    it {
      should route(:get, "/bigbluebutton/servers/1/rooms/new").
        to(:action => :new, :server_id => "1")
    }
    it {
      should route(:get, "/bigbluebutton/servers/1/rooms/1/edit").
        to(:action => :edit, :server_id => "1", :id => "1")
    }
    it {
      should route(:get, "/bigbluebutton/servers/1/rooms/1").
        to(:action => :show, :server_id => "1", :id => "1")
    }
    it {
      should route(:put, "/bigbluebutton/servers/1/rooms/1").
        to(:action => :update, :server_id => "1", :id => "1")
    }
    it {
      should route(:delete, "/bigbluebutton/servers/1/rooms/1").
        to(:action => :destroy, :server_id => "1", :id => "1")
    }
  end

end

