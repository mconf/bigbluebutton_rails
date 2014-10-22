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
