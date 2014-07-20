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

  describe "#set_on_config_xml" do
    let(:config_xml) { '<config></config>' }

    context "if the xml changed" do
      before {
        # set a few values to true and a few to false to test both cases
        room_options.update_attributes(:default_layout => "AnyLayout",
                                       :presenter_share_only => true,
                                       :auto_start_video => false,
                                       :auto_start_audio => false)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:set_attribute)
          .with('layout', 'defaultLayout', "AnyLayout", false)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:set_attribute)
          .with('VideoconfModule', 'presenterShareOnly', true, true)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:set_attribute)
          .with('PhoneModule', 'presenterShareOnly', true, true)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:set_attribute)
          .with('VideoconfModule', 'autoStart', false, true)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:set_attribute)
          .with('PhoneModule', 'autoJoin', false, true)
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
        room_options.update_attributes(:default_layout => "AnyLayout",
                                       :presenter_share_only => false,
                                       :auto_start_video => false,
                                       :auto_start_audio => false)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:set_attribute)
          .with('layout', 'defaultLayout', "AnyLayout", false)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:set_attribute)
          .with('VideoconfModule', 'presenterShareOnly', false, true)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:set_attribute)
          .with('PhoneModule', 'presenterShareOnly', false, true)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:set_attribute)
          .with('VideoconfModule', 'autoStart', false, true)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:set_attribute)
          .with('PhoneModule', 'autoJoin', false, true)
        BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:is_modified?).and_return(false)
      }
      subject { room_options.set_on_config_xml(config_xml) }
      it("returns false") { should be_false }
    end

    context "if #default_layout is" do
      context "nil" do
        before {
          room_options.update_attributes(:default_layout => nil)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_not_receive(:set_attribute)
            .with('layout', 'defaultLayout', anything, anything)
        }
        it("doesn't set the property in the xml") { room_options.set_on_config_xml(config_xml) }
      end

      context "empty string" do
        before {
          room_options.update_attributes(:default_layout => "")
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_not_receive(:set_attribute)
            .with('layout', 'defaultLayout', anything, anything)
        }
        it("doesn't set the property in the xml") { room_options.set_on_config_xml(config_xml) }
      end
    end

    context "if #presenter_share_only is" do
      context "nil" do
        before {
          room_options.update_attributes(:presenter_share_only => nil)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_not_receive(:set_attribute)
            .with('VideoconfModule', 'presenterShareOnly', anything, anything)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_not_receive(:set_attribute)
            .with('PhoneModule', 'presenterShareOnly', anything, anything)
        }
        it("doesn't set the property in the xml") { room_options.set_on_config_xml(config_xml) }
      end
    end

    context "if #auto_start_video is" do
      context "nil" do
        before {
          room_options.update_attributes(:auto_start_video => nil)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_not_receive(:set_attribute)
            .with('VideoconfModule', 'autoStart', anything, anything)
        }
        it("doesn't set the property in the xml") { room_options.set_on_config_xml(config_xml) }
      end
    end

    context "if #auto_start_audio is" do
      context "nil" do
        before {
          room_options.update_attributes(:auto_start_audio => nil)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_not_receive(:set_attribute)
            .with('PhoneModule', 'autoJoin', anything, anything)
        }
        it("doesn't set the property in the xml") {room_options.set_on_config_xml(config_xml) }
      end
    end

  end

  describe "#is_modified?" do
    context "if default_layout is set" do
      before { room_options.update_attributes(:default_layout => 'Any') }
      subject { room_options.is_modified? }
      it("returns true") { should be_true }
    end

    context "if default_layout is not set" do
      before { room_options.update_attributes(:default_layout => nil) }
      subject { room_options.is_modified? }
      it("returns false") { should be_false }
    end

    context "if default_layout is empty" do
      before { room_options.update_attributes(:default_layout => "") }
      subject { room_options.is_modified? }
      it("returns true") { should be_true }
    end

    context "if presenter_share_only is set" do
      before { room_options.update_attributes(:presenter_share_only => true) }
      subject { room_options.is_modified? }
      it("returns true") { should be_true}
    end

    context "if presenter_share_only is not set" do
      before { room_options.update_attributes(:presenter_share_only => nil) }
      subject { room_options.is_modified? }
      it("returns false") { should be_false }
    end

    context "if auto_start_video is set" do
      before { room_options.update_attributes(:auto_start_video => true) }
      subject { room_options.is_modified? }
      it("returns true") { should be_true}
    end

    context "if auto_start_video is not set" do
      before { room_options.update_attributes(:auto_start_video => nil) }
      subject { room_options.is_modified? }
      it("returns false" ) { should be_false }
    end

    context "if auto_start_audio is set" do
      before { room_options.update_attributes(:auto_start_audio => true) }
      subject { room_options.is_modified? }
      it("returns true") { should be_true}
    end

    context "if auto_start_audio is not set" do
      before { room_options.update_attributes(:auto_start_audio => nil) }
      subject { room_options.is_modified? }
      it("returns false" ) { should be_false }
    end
  end

end
