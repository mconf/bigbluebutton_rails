require 'spec_helper'

describe Bigbluebutton::ServersController do
  include Shoulda::Matchers::ActionController

  describe "routing" do
    it { should route(:get, "/bigbluebutton/servers").to(:action => :index) }
  end
  # TODO test all the default routes for 'servers'

end

