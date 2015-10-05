require 'spec_helper'

describe BigbluebuttonRails::BackgroundTasks do

  describe ".finish_meetings" do

    context "set meetings that ended as not running" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, running: true, room: room) }
      before {
        BigBlueButton::BigBlueButtonApi.any_instance
          .stub(:get_api_version).and_return("0.9")
        BigBlueButton::BigBlueButtonApi.any_instance
          .should_receive(:is_meeting_running?).once.with(room.meetingid).and_return(false)
      }
      before(:each) { BigbluebuttonRails::BackgroundTasks.finish_meetings }
      it { meeting.reload.running.should be false }
    end

    context "doesn't change meetings that are still running" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, running: true, room: room) }
      before {
        BigBlueButton::BigBlueButtonApi.any_instance
          .stub(:get_api_version).and_return("0.9")
        BigBlueButton::BigBlueButtonApi.any_instance
          .should_receive(:is_meeting_running?).once.with(room.meetingid).and_return(true)
      }
      before(:each) { BigbluebuttonRails::BackgroundTasks.finish_meetings }
      it { meeting.reload.running.should be true }
    end

    context "ignores meetings that are not running" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, running: false, room: room) }
      before {
        BigBlueButton::BigBlueButtonApi.any_instance.should_not_receive(:is_meeting_running?)
      }
      before(:each) { BigbluebuttonRails::BackgroundTasks.finish_meetings }
      it { meeting.reload.running.should be false }
    end

    it "works for multiple meetings"
  end

  describe ".update_recordings" do

    context "fetches the meetings for all servers" do
      let!(:server1) { FactoryGirl.create(:bigbluebutton_server) }
      let!(:server2) { FactoryGirl.create(:bigbluebutton_server) }
      before {
        BigbluebuttonServer.stub(:find_each).and_yield(server1).and_yield(server2)
        server1.should_receive(:fetch_recordings).once
        server2.should_receive(:fetch_recordings).once
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings }
    end

    it "doesn't break if exceptions are returned"
  end
end
