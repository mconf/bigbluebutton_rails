require 'spec_helper'

describe BigbluebuttonGetStatsForRecentWorker do

  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonGetStatsForRecentWorker.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end

  describe "#perform" do

    it "runs BigbluebuttonRails::BackgroundTasks.get_stats" do
      expect(BigbluebuttonRails::BackgroundTasks).to receive(:get_stats).once
      BigbluebuttonGetStatsForRecentWorker.perform
    end

    context "gets stats only for meetings ended, not yet with stats, and from the past 7 days" do
      RSpec::Matchers.define :my_meetings do |meetings|
        match { |actual|
          meetings.inject(true) { |ret, meeting|
            ret && actual.map(&:meetingid).include?(meeting.meetingid)
          } && actual.count == meetings.count
        }
      end

      let(:now) { DateTime.now.utc }
      let!(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting, ended: true, create_time: now.to_i * 1000, got_stats: nil) }
      let!(:meeting2) { FactoryGirl.create(:bigbluebutton_meeting, ended: true, create_time: now.to_i * 1000, got_stats: 'nodata') }
      let!(:meeting3) { FactoryGirl.create(:bigbluebutton_meeting, ended: true, create_time: (now - 5.days).to_i * 1000, got_stats: "failed") }
      let!(:meeting4) { FactoryGirl.create(:bigbluebutton_meeting, ended: true, create_time: now.to_i * 1000, got_stats: "yes") }
      let!(:meeting5) { FactoryGirl.create(:bigbluebutton_meeting, ended: true, create_time: (now - 8.days).to_i * 1000, got_stats: "failed") }
      before {
        expected = my_meetings([meeting1, meeting2, meeting3])
        expect(BigbluebuttonRails::BackgroundTasks).to receive(:get_stats).with(expected)
      }
      it { BigbluebuttonGetStatsForRecentWorker.perform }
    end
  end
end
