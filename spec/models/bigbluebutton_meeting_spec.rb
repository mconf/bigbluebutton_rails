# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonMeeting do
  it "loaded correctly" do
    BigbluebuttonMeeting.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_meeting) }

  it { should belong_to(:room) }
  it { should validate_presence_of(:room) }

  it { should have_one(:recording).dependent(:nullify) }

  it { should validate_presence_of(:meetingid) }
  it { should ensure_length_of(:meetingid).is_at_least(1).is_at_most(100) }

  it { should validate_presence_of(:create_time) }
  it { should validate_uniqueness_of(:create_time).scoped_to(:room_id) }

  context "got_stats included in" do
    it { should allow_value(nil).for(:got_stats) }
    it { should allow_value('yes').for(:got_stats) }
    it { should allow_value('not_supported').for(:got_stats) }
    it { should_not allow_value('no').for(:got_stats) }
    it { should_not allow_value(true).for(:got_stats) }
    it { should_not allow_value(false).for(:got_stats) }
    it { should_not allow_value('').for(:got_stats) }
  end

  describe "#created_by?" do
    let(:target) { FactoryGirl.create(:bigbluebutton_meeting) }

    context "if the user informed is nil" do
      it { target.created_by?(nil).should be_falsey }
    end

    context "with a valid user informed" do
      let(:user) { FactoryGirl.build(:user) }

      context "if the meeting has no creator_id" do
        before { target.update_attributes(:creator_id => nil) }
        it { target.created_by?(user).should be_falsey }
      end

      context "if it wasn't the user that created the meeting" do
        let(:user2) { FactoryGirl.build(:user) }
        before { target.update_attributes(:creator_id => user2.id, :creator_name => user2.name) }
        it { target.created_by?(user).should be_falsey }
      end

      context "if it was the user that created the meeting" do
        before { target.update_attributes(:creator_id => user.id, :creator_name => user.name) }
        it { target.created_by?(user).should be_truthy }
      end
    end
  end

  describe "#fetch_and_update_stats" do
    let!(:room) { FactoryGirl.create(:bigbluebutton_room) }
    let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: true, running: false, create_time: "1496849802529") }
    before { mock_server_and_api }

    let(:hash_info) {
      { :returncode=>true, :stats=>{:meeting=>[{:meetingID=>meeting.meetingid, :meetingName=>"admin",
        :recordID=>"a0a5186e8ad1c576461da995a2b2e894dc7a1cfb-1496849802529", :epochStartTime=>"1496849802529", :startTime=>"6461874839",
        :endTime=>"6461893242", :participants=>{:participant=>{:userID=>"kha2sycmaotz_2", :externUserID=>"1", :userName=>"admin", :joinTime=>"6461875282",
        :leftTime=>"6461893242"}}}, {:meetingID=>meeting.meetingid, :meetingName=>"admin", :recordID=>"a0a5186e8ad1c576461da995a2b2e894dc7a1cfb-1496947081207",
        :epochStartTime=>"1496947081207", :startTime=>"6559154251", :endTime=>"6559174875", :participants=>{:participant=>{:userID=>"ipy6lxew6hwv_2", :externUserID=>"1",
        :userName=>"admin", :joinTime=>"6559158878", :leftTime=>"6559174875"}}}]}, :messageKey=>"", :message=>""
      }
    }

    context "fetches stats for meetings" do
      it { should respond_to(:fetch_and_update_stats) }

      context "fetches meeting stats and creates attendees" do
        before {
          mocked_api.should_receive(:send_api_request).
            with(:getStats, { meetingID: meeting.meetingid }).and_return(hash_info)
          room.should_receive(:select_server).and_return(mocked_server)
        }
        it { expect { meeting.fetch_and_update_stats }.to change{ BigbluebuttonAttendee.count }.by(1) }
        it {
          meeting.fetch_and_update_stats
          meeting.reload.finish_time.should_not be_nil
        }
        it {
          meeting.fetch_and_update_stats
          meeting.reload.got_stats.should eql("yes")
        }
      end
    end

    context "if the server does not support getStats api call" do
      let!(:exception) {
        BigBlueButton::BigBlueButtonException.new('any error')
      }
      before {
        room.should_receive(:select_server).and_return(mocked_server)
        expect(mocked_api).to receive(:send_api_request).with(:getStats, { meetingID: meeting.meetingid }) { raise exception }
        expect(meeting).not_to receive(:get_stats)
      }
      it { expect { meeting.fetch_and_update_stats }.not_to raise_exception }
      it { expect { meeting.fetch_and_update_stats }.not_to change{ BigbluebuttonAttendee.count } }
      it {
        meeting.fetch_and_update_stats
        meeting.reload.finish_time.should be_nil
      }
      it {
        meeting.fetch_and_update_stats
        meeting.reload.got_stats.should eql("not_supported")
      }
    end

    context "doesn't recreate attendees that already exist" do
      before {
        mocked_api.stub(:send_api_request).
          with(:getStats, { meetingID: meeting.meetingid }).and_return(hash_info)
        room.should_receive(:select_server).and_return(mocked_server)
      }
      it {
        expect { meeting.fetch_and_update_stats }.to change{ BigbluebuttonAttendee.count }.by(1)
        expect { meeting.fetch_and_update_stats }.not_to change{ BigbluebuttonAttendee.count }
      }
    end
  end

end
