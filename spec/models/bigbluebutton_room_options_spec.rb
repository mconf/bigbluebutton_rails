# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonRoomOptions do
  it "loaded correctly" do
    BigbluebuttonRoomOptions.new.should be_a_kind_of(ActiveRecord::Base)
  end

  let(:room_options) { FactoryGirl.create(:bigbluebutton_room).room_options }

  it { should belong_to(:room) }
  it {
    room = FactoryGirl.create(:bigbluebutton_room)
    BigbluebuttonRoomOptions.new(:room => room)
      .room.should be_a_kind_of(BigbluebuttonRoom) }
  it { should validate_presence_of(:room_id) }

  describe "#get_available_layouts" do
    it "returns the layouts available" do
      expected = ["Default", "Video Chat", "Meeting", "Webinar", "Lecture assistant", "Lecture"]
      room_options.get_available_layouts.should eql(expected)
    end
  end

  describe "set_on_config_xml" do
    let(:config_xml) { '<config></config>' }
    before {
      BigBlueButton::BigBlueButtonConfigXml.any_instance
        .should_receive(:set_attribute)
        .with('layout', 'defaultLayout', room_options.default_layout, false)
    }

    context "if the xml changed" do
      before {
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:is_modified?).and_return(true)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:as_string).and_return('new xml as string')
      }
      subject { room_options.set_on_config_xml(config_xml) }
      it("returns the new xml") { should eql('new xml as string') }
    end

    context "if the xml did not change" do
      before {
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:is_modified?).and_return(false)
      }
      subject { room_options.set_on_config_xml(config_xml) }
      it("returns false") { should be_false }
    end
  end

  describe "is_modified?" do
    context "if default_layout is set" do
      before { room_options.update_attributes(:default_layout => 'Any') }
      subject { room_options.is_modified? }
      it("returns true") { should be_true }
    end

    context "if default _layout is not set" do
      subject { room_options.is_modified? }
      it("returns true") { should be_false }
    end
  end

end
