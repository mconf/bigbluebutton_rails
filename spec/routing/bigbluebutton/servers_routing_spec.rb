require 'spec_helper'

describe Bigbluebutton::ServersController do
  include Shoulda::Matchers::ActionController

  describe "routing" do
    it { should route(:get, "/bigbluebutton/servers").to(:action => :index) }
    it { should route(:post, "/bigbluebutton/servers").to(:action => :create) }
    it { should route(:get, "/bigbluebutton/servers/new").to(:action => :new) }
    it { should route(:get, "/bigbluebutton/servers/1/edit").to(:action => :edit, :id => 1) }
    it { should route(:get, "/bigbluebutton/servers/1").to(:action => :show, :id => 1) }
    it { should route(:put, "/bigbluebutton/servers/1").to(:action => :update, :id => 1) }
    it { should route(:delete, "/bigbluebutton/servers/1").to(:action => :destroy, :id => 1) }
  end

end

