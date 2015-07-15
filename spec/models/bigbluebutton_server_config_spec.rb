# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonServerConfig do

  before { mock_server_and_api }

  it { should belong_to(:server) }
  it { should validate_presence_of(:server_id) }
  it { should serialize(:available_layouts).as(Array) }

  describe "serializes #available_layouts as an Array" do
    let(:config) { FactoryGirl.create(:bigbluebutton_server_config) }
    let(:layouts) { ["layout1", "layout2"] }

    it {
      config.update_attributes(available_layouts: layouts)
      config.available_layouts.should eq(layouts)
    }
  end

  describe "#update_config" do
    let(:config) { FactoryGirl.create(:bigbluebutton_server_config, server: mocked_server) }
    let(:layouts) { ["layout1", "layout2"] }
    let(:new_layouts) { ["layout3", "layout4"] }

    before {
      mocked_api.should_receive(:get_default_config_xml).and_return("<config></config>")
      config.update_attributes(available_layouts: layouts)
    }

    context "when there are new layouts in the server" do
      before {
        mocked_api.should_receive(:get_available_layouts).and_return(new_layouts)
        config.update_config
      }
      it { config.available_layouts.should eql new_layouts }
    end

    context "when there are no new layouts" do
      before {
        mocked_api.should_receive(:get_available_layouts).once.and_return(nil)
        expect(config).not_to receive(:update_attributes)
        config.update_config
      }
      it { config.available_layouts.should eql layouts }
    end

    context "rescues from BigBlueButton::BigBlueButtonException" do
      before {
        mocked_api.stub(:get_available_layouts) { raise BigBlueButton::BigBlueButtonException.new }
        expect(config).not_to receive(:update_attributes)
      }
      it {
        expect { config.update_config }.not_to raise_error
      }
    end
  end

  describe "#available_layouts_names" do
    let(:layouts) { ["layout1", "bbb.test.layout2", "Wëird Chárs"] }
    let(:expected) { ["layout1", "layout2", "Wëird Chárs"] }
    let(:config) { FactoryGirl.create(:bigbluebutton_server_config, available_layouts: layouts) }

    before {
      I18n.stub(:t) { |value|
        case value
        when "bigbluebutton_rails.server_configs.layouts.layout1"
          "Layout1 Localized"
        when "bigbluebutton_rails.server_configs.layouts.layout2"
          "Layout2 Localized"
        when "bigbluebutton_rails.server_configs.layouts.weird_chars"
          "Weird Localized"
        else
          nil
        end
      }
    }

    it {
      config.available_layouts_names.should eql(['Layout1 Localized', 'Layout2 Localized', 'Weird Localized'])
    }
  end

  describe "#available_layouts_for_select" do
    let(:layouts) { ["layout1", "bbb.test.layout2", "Wëird Chárs"] }
    let(:expected) { ["layout1", "layout2", "Wëird Chárs"] }
    let(:config) { FactoryGirl.create(:bigbluebutton_server_config, available_layouts: layouts) }

    before {
      I18n.stub(:t) { |value|
        case value
        when "bigbluebutton_rails.server_configs.layouts.layout1"
          "Layout1 Localized"
        when "bigbluebutton_rails.server_configs.layouts.layout2"
          "Layout2 Localized"
        when "bigbluebutton_rails.server_configs.layouts.weird_chars"
          "Weird Localized"
        else
          nil
        end
      }
    }

    it {
      config.available_layouts_for_select.should eql(
        [
          ['Layout1 Localized', 'layout1'],
          ['Layout2 Localized', 'bbb.test.layout2'],
          ['Weird Localized', 'Wëird Chárs']
        ]
      )
    }
  end
end
