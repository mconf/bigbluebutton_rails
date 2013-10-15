# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonMeeting do
  it "loaded correctly" do
    BigbluebuttonMeeting.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_meeting) }

  it { should belong_to(:server) }
  it { should_not validate_presence_of(:server_id) }

  it { should belong_to(:room) }
  it { should validate_presence_of(:room) }

  it { should have_one(:recording).dependent(:nullify) }

  it { should validate_presence_of(:meetingid) }
  it { should ensure_length_of(:meetingid).is_at_least(1).is_at_most(100) }

  it { should validate_presence_of(:start_time) }
  it { should validate_uniqueness_of(:start_time).scoped_to(:room_id) }
end
