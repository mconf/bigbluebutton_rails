require 'spec_helper'

describe BigbluebuttonRails::BackgroundTasks do

  describe ".get_stats" do
    before { mock_server_and_api }

    context "calls #fetch_and_update_stats for all meetings" do
      let(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting) }
      let(:meeting2) { FactoryGirl.create(:bigbluebutton_meeting) }
      let(:meeting3) { FactoryGirl.create(:bigbluebutton_meeting) }
      before {
        BigbluebuttonMeeting.stub(:find_each)
          .and_yield(meeting1)
          .and_yield(meeting2)
          .and_yield(meeting3)
        meeting1.should_receive(:fetch_and_update_stats)
        meeting2.should_receive(:fetch_and_update_stats)
        meeting3.should_receive(:fetch_and_update_stats)
      }
      it { BigbluebuttonRails::BackgroundTasks.get_stats }
    end

    context "calls get stats only for the target meetings" do
      let(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting) }
      let(:meeting2) { FactoryGirl.create(:bigbluebutton_meeting) }
      let(:meeting3) { FactoryGirl.create(:bigbluebutton_meeting) }
      before {
        @filter = BigbluebuttonMeeting.where(meetingid: meeting1.meetingid)
        @filter.stub(:find_each).and_yield(meeting1)
        meeting1.should_receive(:fetch_and_update_stats)
        meeting2.should_not_receive(:fetch_and_update_stats)
        meeting3.should_not_receive(:fetch_and_update_stats)
      }
      it { BigbluebuttonRails::BackgroundTasks.get_stats(@filter) }
    end
  end

  describe ".finish_meetings" do
    let!(:api) { double(BigBlueButton::BigBlueButtonApi) }

    context "set meetings that ended as not running and ended" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      let!(:exception) {
        e = BigBlueButton::BigBlueButtonException.new('Test error')
        e.key = 'notFound'
        e
      }

      before {
        BigBlueButton::BigBlueButtonApi.any_instance
          .stub(:get_api_version).and_return("0.9")
        BigBlueButton::BigBlueButtonApi.any_instance
          .should_receive(:get_meeting_info).once { raise exception }
      }
      before(:each) { BigbluebuttonRails::BackgroundTasks.finish_meetings }
      it { meeting.reload.running.should be(false) }
      it { meeting.reload.ended.should be(true) }
    end

    context "doesn't change meetings that are still running" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      before {
        BigBlueButton::BigBlueButtonApi.any_instance
          .stub(:get_api_version).and_return("0.9")
        BigBlueButton::BigBlueButtonApi.any_instance
          .should_receive(:get_meeting_info).once.and_return({ running: true })
      }
      before(:each) { BigbluebuttonRails::BackgroundTasks.finish_meetings }
      it { meeting.reload.running.should be(true) }
      it { meeting.reload.ended.should be(false) }
    end

    context "ignores meetings that already ended" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, ended: true, room: room) }
      before(:each) {
        BigbluebuttonRoom.any_instance.should_not_receive(:fetch_meeting_info)
        BigbluebuttonRails::BackgroundTasks.finish_meetings
      }
      it { meeting.reload.running.should be(false) }
    end

    context "considers both meetings running and not running" do
      let(:room1) { FactoryGirl.create(:bigbluebutton_room) }
      let(:room2) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting, ended: false, running: true, room: room1) }
      let!(:meeting2) { FactoryGirl.create(:bigbluebutton_meeting, ended: false, running: false, room: room2) }
      let!(:exception) {
        e = BigBlueButton::BigBlueButtonException.new('Test error')
        e.key = 'notFound'
        e
      }

      before {
        BigBlueButton::BigBlueButtonApi.any_instance
          .stub(:get_api_version).and_return("0.9")
        BigBlueButton::BigBlueButtonApi.any_instance.stub(:get_meeting_info) { raise exception }
      }
      before(:each) { BigbluebuttonRails::BackgroundTasks.finish_meetings }
      it { meeting1.reload.running.should be(false) }
      it { meeting1.reload.ended.should be(true) }
      it { meeting1.reload.running.should be(false) }
      it { meeting1.reload.ended.should be(true) }
    end

    context "ignore meetings that have no room" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      before(:each) {
        BigbluebuttonRoom.any_instance.should_not_receive(:fetch_meeting_info)
        meeting.room.delete
        BigbluebuttonRails::BackgroundTasks.finish_meetings
      }
      it { meeting.reload.running.should be(true) }
    end

    context "calls finish_meetings if an exception 'notFound' is raised" do
      let!(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      let!(:exception) {
        e = BigBlueButton::BigBlueButtonException.new('Test error')
        e.key = 'notFound'
        e
      }

      before {
        BigbluebuttonServer.any_instance.should_receive(:api) { api }
        expect(api).to receive(:get_meeting_info).once { raise exception }
        BigbluebuttonRoom.any_instance.should_receive(:finish_meetings).once
      }
      it { expect { BigbluebuttonRails::BackgroundTasks.finish_meetings }.not_to raise_exception }
    end

    context "calls finish_meetings if an exception other than 'notFound' is raised" do
      let!(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      let!(:exception) {
        e = BigBlueButton::BigBlueButtonException.new('Test error')
        e.key = 'anythingElse'
        e
      }

      before {
        BigbluebuttonServer.any_instance.should_receive(:api) { api }
        expect(api).to receive(:get_meeting_info).once { raise exception }
        BigbluebuttonRoom.any_instance.should_receive(:finish_meetings)
      }
      it { expect { BigbluebuttonRails::BackgroundTasks.finish_meetings }.not_to raise_exception }
    end

    context "calls finish_meetings if an exception with a blank key is raised" do
      let!(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      let!(:exception) {
        e = BigBlueButton::BigBlueButtonException.new('Test error')
        e.key = ''
        e
      }

      before {
        BigbluebuttonServer.any_instance.should_receive(:api) { api }
        expect(api).to receive(:get_meeting_info).once { raise exception }
        BigbluebuttonRoom.any_instance.should_receive(:finish_meetings)
      }
      it { expect { BigbluebuttonRails::BackgroundTasks.finish_meetings }.not_to raise_exception }
    end
  end

  describe ".update_recordings" do
    context "fetches the meetings for all servers" do
      let!(:server1) { FactoryGirl.create(:bigbluebutton_server) }
      let!(:server2) { FactoryGirl.create(:bigbluebutton_server) }
      before {
        BigbluebuttonServer.stub(:find_each).and_yield(server1).and_yield(server2)
        server1.should_receive(:fetch_recordings).once.with(nil, true)
        server2.should_receive(:fetch_recordings).once.with(nil, true)
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings }
    end

    it "doesn't break if exceptions are returned"
  end
end
