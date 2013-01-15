# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonRecording do
  it "loaded correctly" do
    BigbluebuttonRecording.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_recording) }

  it { should belong_to(:room) }
  it { should validate_presence_of(:room_id) }

  it { should validate_presence_of(:recordingid) }
  it { should validate_uniqueness_of(:recordingid) }

  [:recordingid, :meetingid, :name, :published, :start_time,
   :end_time].each do |attribute|
    it { should allow_mass_assignment_of(attribute) }
  end

  it { should have_many(:metadata).dependent(:destroy) }

  it { should have_many(:playback_formats).dependent(:destroy) }

end
