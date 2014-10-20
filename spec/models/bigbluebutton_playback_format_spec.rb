# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonPlaybackFormat do
  it "loaded correctly" do
    BigbluebuttonPlaybackFormat.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_playback_format) }

  it { should belong_to(:recording) }
  it { should belong_to(:playback_type) }

  it { should validate_presence_of(:recording_id) }
  it { should validate_presence_of(:playback_type_id) }

  it { should_not validate_presence_of(:url) }
  it { should_not validate_presence_of(:length) }

  it { should delegate_method(:name).to(:playback_type) }
  it { should delegate_method(:visible).to(:playback_type) }
  it { should delegate_method(:identifier).to(:playback_type) }

  it("alias :format_type to :identifier") {
    target = FactoryGirl.create(:bigbluebutton_playback_format)
    target.playback_type.identifier = "anything"
    target.format_type.should eql("anything")
  }

  describe "#length_in_secs" do
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: nil).length_in_secs.should eql(0) }
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: "").length_in_secs.should eql(0) }
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: -1).length_in_secs.should eql(0) }
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: 0).length_in_secs.should eql(0) }
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: 5).length_in_secs.should eql(300) }
    it { FactoryGirl.create(:bigbluebutton_playback_format, length: 99).length_in_secs.should eql(5940) }
  end
end
