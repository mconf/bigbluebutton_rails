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

  describe "#set_on_config_xml" do
    let(:config_xml) { '<config></config>' }

    context "if the xml changed" do
      before {
        # set a few values to true and a few to false to test both cases
        room_options.update_attributes(:default_layout => "AnyLayout",
                                       :presenter_share_only => true,
                                       :auto_start_video => false,
                                       :auto_start_audio => false,
                                       :background => "http://mconf.org/anything")
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
          .should_receive(:set_attribute)
          .with('branding', 'background', "http://mconf.org/anything", false)
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
        BigBlueButton::BigBlueButtonConfigXml.stub(:set_attribute)

       BigBlueButton::BigBlueButtonConfigXml.any_instance
          .should_receive(:is_modified?).and_return(false)
      }
      subject { room_options.set_on_config_xml(config_xml) }
      it("returns false") { should be(false) }
    end

    context "if #default_layout is" do
      context "a valid string" do
        before {
          room_options.update_attributes(:default_layout => "my layout")
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_receive(:set_attribute)
            .with('layout', 'defaultLayout', "my layout", anything)
        }
        it("sets the property in the xml") { room_options.set_on_config_xml(config_xml) }
      end

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

      context "true" do
        before {
          room_options.update_attributes(:presenter_share_only => true)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_receive(:set_attribute)
            .with('VideoconfModule', 'presenterShareOnly', true, anything)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_receive(:set_attribute)
            .with('PhoneModule', 'presenterShareOnly', true, anything)
        }
        it("sets the property in the xml") { room_options.set_on_config_xml(config_xml) }
      end

      context "false" do
        before {
          room_options.update_attributes(:presenter_share_only => false)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_receive(:set_attribute)
            .with('VideoconfModule', 'presenterShareOnly', false, anything)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_receive(:set_attribute)
            .with('PhoneModule', 'presenterShareOnly', false, anything)
        }
        it("sets the property in the xml") { room_options.set_on_config_xml(config_xml) }
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

      context "true" do
        before {
          room_options.update_attributes(:auto_start_video => true)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_receive(:set_attribute)
            .with('VideoconfModule', 'autoStart', true, anything)
        }
        it("sets the property in the xml") { room_options.set_on_config_xml(config_xml) }
      end

      context "false" do
        before {
          room_options.update_attributes(:auto_start_video => false)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_receive(:set_attribute)
            .with('VideoconfModule', 'autoStart', false, anything)
        }
        it("sets the property in the xml") { room_options.set_on_config_xml(config_xml) }
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

      context "true" do
        before {
          room_options.update_attributes(:auto_start_audio => true)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_receive(:set_attribute)
            .with('PhoneModule', 'autoJoin', true, anything)
        }
        it("sets the property in the xml") {room_options.set_on_config_xml(config_xml) }
      end

      context "false" do
        before {
          room_options.update_attributes(:auto_start_audio => false)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_receive(:set_attribute)
            .with('PhoneModule', 'autoJoin', false, anything)
        }
        it("sets the property in the xml") {room_options.set_on_config_xml(config_xml) }
      end
    end

    context "if #background is" do
      context "a valid string" do
        before {
          room_options.update_attributes(:background => "my background")
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_receive(:set_attribute)
            .with('branding', 'background', 'my background', anything)
        }
        it("sets the property in the xml") { room_options.set_on_config_xml(config_xml) }
      end

      context "nil" do
        before {
          room_options.update_attributes(:background => nil)
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_not_receive(:set_attribute)
            .with('branding', 'background', anything, anything)
        }
        it("doesn't set the property in the xml") {room_options.set_on_config_xml(config_xml) }
      end

      context "empty string" do
        before {
          room_options.update_attributes(:background => "")
          BigBlueButton::BigBlueButtonConfigXml.any_instance
            .should_not_receive(:set_attribute)
            .with('branding', 'background', anything, anything)
        }
        it("doesn't set the property in the xml") { room_options.set_on_config_xml(config_xml) }
      end
    end
  end

  describe "#is_modified?" do
    context "if default_layout is set" do
      before { room_options.update_attributes(:default_layout => 'Any') }
      subject { room_options.is_modified? }
      it { should be(true) }
    end

    context "if default_layout is not set" do
      before { room_options.update_attributes(:default_layout => nil) }
      subject { room_options.is_modified? }
      it { should be(false) }
    end

    context "if default_layout is empty" do
      before { room_options.update_attributes(:default_layout => "") }
      subject { room_options.is_modified? }
      it { should be(false) }
    end

    context "if presenter_share_only is set" do
      before { room_options.update_attributes(:presenter_share_only => true) }
      subject { room_options.is_modified? }
      it { should be(true) }
    end

    context "if presenter_share_only is not set" do
      before { room_options.update_attributes(:presenter_share_only => nil) }
      subject { room_options.is_modified? }
      it { should be(false) }
    end

    context "if auto_start_video is set" do
      before { room_options.update_attributes(:auto_start_video => true) }
      subject { room_options.is_modified? }
      it { should be(true) }
    end

    context "if auto_start_video is not set" do
      before { room_options.update_attributes(:auto_start_video => nil) }
      subject { room_options.is_modified? }
      it { should be(false) }
    end

    context "if auto_start_audio is set" do
      before { room_options.update_attributes(:auto_start_audio => true) }
      subject { room_options.is_modified? }
      it { should be(true) }
    end

    context "if auto_start_audio is not set" do
      before { room_options.update_attributes(:auto_start_audio => nil) }
      subject { room_options.is_modified? }
      it { should be(false) }
    end

    context "if background is set" do
      before { room_options.update_attributes(:background => true) }
      subject { room_options.is_modified? }
      it { should be(true) }
    end

    context "if background is not set" do
      before { room_options.update_attributes(:background => nil) }
      subject { room_options.is_modified? }
      it { should be(false) }
    end
  end

end
