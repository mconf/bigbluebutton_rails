require 'spec_helper'

describe BigbluebuttonUpdateServerConfigs do

  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonUpdateServerConfigs.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end

  describe "#perform" do
    let!(:servers) {
      [ FactoryGirl.create(:bigbluebutton_server),
        FactoryGirl.create(:bigbluebutton_server),
        FactoryGirl.create(:bigbluebutton_server) ]
    }
    before {
      BigbluebuttonServer.stub(:find_each)
        .and_yield(servers[0])
        .and_yield(servers[1])
        .and_yield(servers[2])
      expect(servers[0]).to receive(:update_config).once
      expect(servers[1]).to receive(:update_config).once
      expect(servers[2]).to receive(:update_config).once
    }
    it { BigbluebuttonUpdateServerConfigs.perform }
  end
end
