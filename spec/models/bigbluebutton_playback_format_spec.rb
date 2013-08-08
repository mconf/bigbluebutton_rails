# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonPlaybackFormat do
  it "loaded correctly" do
    BigbluebuttonPlaybackFormat.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_playback_format) }

  it { should belong_to(:recording) }
  it { should validate_presence_of(:recording_id) }

  it { should validate_presence_of(:format_type) }

  it { should_not validate_presence_of(:url) }
  it { should_not validate_presence_of(:length) }
end
