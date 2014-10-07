# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonPlaybackType do
  it "loaded correctly" do
    BigbluebuttonPlaybackType.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_playback_type) }

  it { should validate_presence_of(:identifier) }

  it { should validate_presence_of(:i18n_key) }

  it { should_not validate_presence_of(:visible) }

  it { should have_many(:playback_formats).dependent(:destroy) }
end
