require 'spec_helper'

describe BigbluebuttonRails::BackgroundTasks do

  describe ".get_stats" do
    before { mock_server_and_api }

    context "fetches the stats" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, meetingid: room.meetingid, room: room, ended: true, running: false, create_time: "1496849802529") }
      let!(:exception) {
        e = BigBlueButton::BigBlueButtonException.new('404')
        e
      }
      let(:hash_info) {
        { :returncode=>true, :stats=>{:meeting=>[{:meetingID=>meeting.meetingid, :meetingName=>"admin",
          :recordID=>"a0a5186e8ad1c576461da995a2b2e894dc7a1cfb-1496849802529", :epochStartTime=>"1496849802529", :startTime=>"6461874839",
          :endTime=>"6461893242", :participants=>{:participant=>{:userID=>"kha2sycmaotz_2", :externUserID=>"1", :userName=>"admin", :joinTime=>"6461875282",
          :leftTime=>"6461893242"}}}, {:meetingID=>meeting.meetingid, :meetingName=>"admin", :recordID=>"a0a5186e8ad1c576461da995a2b2e894dc7a1cfb-1496947081207",
          :epochStartTime=>"1496947081207", :startTime=>"6559154251", :endTime=>"6559174875", :participants=>{:participant=>{:userID=>"ipy6lxew6hwv_2", :externUserID=>"1",
          :userName=>"admin", :joinTime=>"6559158878", :leftTime=>"6559174875"}}}]}, :messageKey=>"", :message=>""
        }
      }

      context "creates a new attendee on BigbluebuttonAttendees" do
        before {
          mocked_api.should_receive(:send_api_request).
            with(:getStats, { meetingID: room.meetingid }).and_return(hash_info)
          room.should_receive(:select_server).and_return(mocked_server)
        }
        it { expect { room.fetch_meeting_stats(meeting) }.to change{ BigbluebuttonAttendees.count }.by(1) }
        it { room.fetch_meeting_stats(meeting)
             meeting.reload.finish_time.should_not be_nil
           }
        it { room.fetch_meeting_stats(meeting)
             meeting.reload.got_stats.should eql("yes")
           }
      end

      context "sets the flag if the server does not support getStats" do
        before {
          room.should_receive(:select_server).and_return(mocked_server)
          expect(mocked_api).to receive(:send_api_request).with(:getStats, { meetingID: room.meetingid }) { raise exception }
          expect(room).not_to receive(:get_stats)
        }
        it { expect { room.fetch_meeting_stats(meeting) }.not_to raise_exception }
        it { expect { room.fetch_meeting_stats(meeting) }.not_to change{ BigbluebuttonAttendees.count } }
        it { room.fetch_meeting_stats(meeting)
             meeting.reload.finish_time.should be_nil
           }
        it { room.fetch_meeting_stats(meeting)
             meeting.reload.got_stats.should eql("not_supported")
           }
      end
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
