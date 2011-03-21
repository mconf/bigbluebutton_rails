require 'spec_helper'

describe Bigbluebutton::ServersController do

  render_views

  describe "#index" do
    before(:each) { get :index }
    it { should respond_with(:success) }
    it { should assign_to(:servers).with(BigbluebuttonServer.all) }
  end

end

