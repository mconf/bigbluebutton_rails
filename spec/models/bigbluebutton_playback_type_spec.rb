# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonPlaybackType do
  it "loaded correctly" do
    BigbluebuttonPlaybackType.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_playback_type) }

  it { should validate_presence_of(:identifier) }

  it { should_not validate_presence_of(:visible) }

  it { should have_many(:playback_formats).dependent(:nullify) }

  context "ensures only 0 or 1 records with default=true" do
    context "automatically sets new records as default=false if setting the current as default=true" do
      let!(:first) { FactoryGirl.create(:bigbluebutton_playback_type, default: true) }
      let!(:target) { FactoryGirl.create(:bigbluebutton_playback_type, default: false) }
      before(:each) {
        target.update_attributes(default: true)
      }
      it { target.reload.default.should be(true) }
      it { first.reload.default.should be(false) }
    end

    context "doesn't change other records to default=false if not setting the current as default=true" do
      let!(:first) { FactoryGirl.create(:bigbluebutton_playback_type, default: true) }
      let!(:target) { FactoryGirl.create(:bigbluebutton_playback_type, default: false) }
      before(:each) {
        target.update_attributes(identifier: "any")
      }
      it { target.reload.default.should be(false) }
      it { first.reload.default.should be(true) }
    end

    context "allows all records to have default=false" do
      let!(:first) { FactoryGirl.create(:bigbluebutton_playback_type, default: false) }
      let!(:target) { FactoryGirl.create(:bigbluebutton_playback_type, default: true) }
      before(:each) {
        target.update_attributes(default: false)
      }
      it { target.reload.default.should be(false) }
      it { first.reload.default.should be(false) }
    end
  end

  describe "#name" do
    let(:subject) { FactoryGirl.create(:bigbluebutton_playback_type) }

    it {
      subject.identifier = "presentation"
      subject.name.should eql(I18n.t("bigbluebutton_rails.playback_types.presentation"))
    }

    it {
      subject.identifier = "any_other"
      subject.name.should eql("Any Other")
    }
  end
end
