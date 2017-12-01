require 'spec_helper'

describe BigbluebuttonGetStatsForMeetingWorker do

  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonGetStatsForMeetingWorker.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end

  describe "#perform" do
    let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting) }

    context "calls #fetch_and_update_stats on the meeting" do
      before {
        BigbluebuttonMeeting.stub(:find).and_return(meeting)
        expect(meeting).to receive(:fetch_and_update_stats).once
      }
      it { BigbluebuttonGetStatsForMeetingWorker.perform(meeting.id) }
    end

    context "if there are still tries left" do
      before {
        BigbluebuttonMeeting.stub(:find).and_return(meeting)
        meeting.stub(:fetch_and_update_stats).and_return(false)
        expect(Resque).to receive(:enqueue_in)
                           .with(5.minutes, ::BigbluebuttonGetStatsForMeetingWorker, meeting.id, 1)
                           .once
      }
      it { BigbluebuttonGetStatsForMeetingWorker.perform(meeting.id, 2) }
    end

    context "if already have the stats" do
      before {
        meeting.update_attributes(got_stats: 'yes')
        BigbluebuttonMeeting.stub(:find).and_return(meeting)
        meeting.should_not_receive(:fetch_and_update_stats)
        expect(Resque).not_to receive(:enqueue_in)
      }
      it { BigbluebuttonGetStatsForMeetingWorker.perform(meeting.id, 2) }
    end

    context "if there are still tries left but already got the stats" do
      before {
        BigbluebuttonMeeting.stub(:find).and_return(meeting)
        meeting.stub(:fetch_and_update_stats).and_return(true)
        expect(Resque).not_to receive(:enqueue_in)
      }
      it { BigbluebuttonGetStatsForMeetingWorker.perform(meeting.id, 2) }
    end

    context "if there are no more tries left" do
      before {
        BigbluebuttonMeeting.stub(:find).and_return(meeting)
        meeting.stub(:fetch_and_update_stats)
        expect(Resque).not_to receive(:enqueue_in)
      }
      it { BigbluebuttonGetStatsForMeetingWorker.perform(meeting.id, 0) }
    end

    context "if the meeting id is not found" do
      before {
        BigbluebuttonMeeting.stub(:find).and_return(nil)
        expect(meeting).not_to receive(:fetch_and_update_stats)
        expect(Resque).not_to receive(:enqueue_in)
      }
      it { BigbluebuttonGetStatsForMeetingWorker.perform(meeting.id) }
    end
  end
end
