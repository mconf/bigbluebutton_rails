# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonServerConfig do

  before { mock_server_and_api }

  let(:config) { mocked_server.get_config }
  let(:layouts1) { ["layout1", "layout2"] }
  let(:new_layouts) { ["layout3", "layout4"] }

  it { should belong_to(:server) }
  it { should validate_presence_of(:server_id) }
  it { should serialize(:available_layouts).as(Array) }

  describe "#get_available_layouts" do
    before {
      mocked_api.should_receive(:get_available_layouts).and_return(layouts1)
    }
    it { config.get_available_layouts.should eql layouts1 }
  end

  describe "#update_config" do
    before { 
      mocked_api.should_receive(:get_default_config_xml).and_return("<config></config>")
      config.update_attributes(available_layouts: layouts)
    }

    context "when there are new configs in the server" do
      context "the available layouts have changed" do
        before {
          mocked_api.should_receive(:get_available_layouts).and_return(new_layouts)
          config.update_config
        }
        it { config.get_available_layouts.should eql new_layouts }
      end
    end

    context "when some configs are missing" do
      context "available layouts missing" do
        before {
          mocked_api.should_receive(:get_available_layouts).at_least(:once).and_return(nil)
          expect { config.update_config }.to_not change { config.available_layouts }
        }
        it { config.get_available_layouts.should eql layouts }
      end
    end
  end
end
