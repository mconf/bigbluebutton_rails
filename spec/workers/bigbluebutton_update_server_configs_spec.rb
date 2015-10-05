require 'spec_helper'

describe BigbluebuttonUpdateServerConfigs do

  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonUpdateServerConfigs.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end

  describe "#perform" do
    let!(:servers) {
      [ FactoryGirl.create(:bigbluebutton_server, version: "0.8"),
        FactoryGirl.create(:bigbluebutton_server, version: "0.8"),
        FactoryGirl.create(:bigbluebutton_server, version: "0.8") ]
    }

    context "calls #update_config for each server" do
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

    context "updates the version of each server" do
      let(:new_version) { "0.9" }
      before {
        BigbluebuttonServer.stub(:find_each)
          .and_yield(servers[0])
          .and_yield(servers[1])
          .and_yield(servers[2])
        expect(servers[0]).to receive(:set_api_version_from_server).at_least(:once).and_return(new_version)
        expect(servers[1]).to receive(:set_api_version_from_server).at_least(:once).and_return(new_version)
        expect(servers[2]).to receive(:set_api_version_from_server).at_least(:once).and_return(new_version)
        BigbluebuttonUpdateServerConfigs.perform
      }
      it { servers[0].version.should eql(new_version) }
      it { servers[1].version.should eql(new_version) }
      it { servers[2].version.should eql(new_version) }
    end

  end
end
