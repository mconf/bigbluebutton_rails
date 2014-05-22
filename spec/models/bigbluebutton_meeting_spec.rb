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

  describe "#created_by?" do
    let(:target) { FactoryGirl.create(:bigbluebutton_meeting) }

    context "if the user informed is nil" do
      it { target.created_by?(nil).should be_false }
    end

    context "with a valid user informed" do
      let(:user) { FactoryGirl.build(:user) }

      context "if the meeting has no creator_id" do
        before { target.update_attributes(:creator_id => nil) }
        it { target.created_by?(user).should be_false }
      end

      context "if it wasn't the user that created the meeting" do
        let(:user2) { FactoryGirl.build(:user) }
        before { target.update_attributes(:creator_id => user2.id, :creator_name => user2.name) }
        it { target.created_by?(user).should be_false }
      end

      context "if it was the user that created the meeting" do
        before { target.update_attributes(:creator_id => user.id, :creator_name => user.name) }
        it { target.created_by?(user).should be_true }
      end
    end
  end
end
