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
end
