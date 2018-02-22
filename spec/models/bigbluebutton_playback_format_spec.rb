# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonPlaybackFormat do
  it "loaded correctly" do
    BigbluebuttonPlaybackFormat.new.should be_a_kind_of(ActiveRecord::Base)
  end

  it { should belong_to(:recording) }
  it { should belong_to(:playback_type) }

  it { should validate_presence_of(:recording_id) }

  it { should_not validate_presence_of(:playback_type_id) }
  it { should_not validate_presence_of(:url) }
  it { should_not validate_presence_of(:length) }

  it { should delegate_method(:name).to(:playback_type) }
  it { should delegate_method(:visible).to(:playback_type) }
  it { should delegate_method(:visible?).to(:playback_type) }
  it { should delegate_method(:identifier).to(:playback_type) }
  it { should delegate_method(:default).to(:playback_type) }
  it { should delegate_method(:default?).to(:playback_type) }
  it { should delegate_method(:description).to(:playback_type) }
  it { should delegate_method(:downloadable).to(:playback_type) }
  it { should delegate_method(:downloadable?).to(:playback_type) }

  context "allows nil for delegates to playback_type" do
    let(:target) { FactoryGirl.create(:bigbluebutton_playback_format, playback_type: nil) }
    it { target.name.should be_nil }
    it { target.identifier.should be_nil }
    it { target.visible.should be_nil }
    it { target.visible?.should be_nil }
    it { target.default.should be_nil }
    it { target.default?.should be_nil }
    it { target.format_type.should be_nil }
  end

  it("alias :format_type to :identifier") {
    target = FactoryGirl.create(:bigbluebutton_playback_format)
    target.playback_type.identifier = "anything"
    target.format_type.should eql("anything")
  }

  describe "#ordered" do
    context "when there's a default set" do
      let!(:type_default) { FactoryGirl.create(:bigbluebutton_playback_type, default: true) }
      let!(:type1) { FactoryGirl.create(:bigbluebutton_playback_type, default: false) }
      let!(:type2) { FactoryGirl.create(:bigbluebutton_playback_type, default: false) }
      before {
        @format1 = FactoryGirl.create(:bigbluebutton_playback_format, playback_type: type1)
        @format2 = FactoryGirl.create(:bigbluebutton_playback_format, playback_type: type2)
        @format3 = FactoryGirl.create(:bigbluebutton_playback_format, playback_type: type_default)
        @format4 = FactoryGirl.create(:bigbluebutton_playback_format, playback_type: nil)
      }
      subject { BigbluebuttonPlaybackFormat.ordered }
      it { subject[0].should eql(@format3) }
      it { subject[1].should eql(@format1) }
      it { subject[2].should eql(@format2) }
      it { subject[3].should eql(@format4) }
    end

    context "when there's no default set" do
      let!(:type1) { FactoryGirl.create(:bigbluebutton_playback_type, default: false) }
      let!(:type2) { FactoryGirl.create(:bigbluebutton_playback_type, default: false) }
      before {
        @format1 = FactoryGirl.create(:bigbluebutton_playback_format, playback_type: type1)
        @format2 = FactoryGirl.create(:bigbluebutton_playback_format, playback_type: type2)
        @format3 = FactoryGirl.create(:bigbluebutton_playback_format, playback_type: nil)
      }
      subject { BigbluebuttonPlaybackFormat.ordered }
      it { subject[0].should eql(@format1) }
      it { subject[1].should eql(@format2) }
      it { subject[2].should eql(@format3) }
    end

    context "when there are no formats" do
      subject { BigbluebuttonPlaybackFormat.ordered }
      it { subject.should eql([]) }
    end
  end

  describe "#length_in_secs" do
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: nil).length_in_secs.should eql(0) }
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: "").length_in_secs.should eql(0) }
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: -1).length_in_secs.should eql(0) }
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: 0).length_in_secs.should eql(0) }
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: 5).length_in_secs.should eql(300) }
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: 99).length_in_secs.should eql(5940) }
  end
end
