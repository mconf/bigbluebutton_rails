require 'spec_helper'

describe BigbluebuttonGetStatsWorker do

  it "runs BigbluebuttonRails::BackgroundTasks.get_stats" do
    expect(BigbluebuttonRails::BackgroundTasks).to receive(:get_stats).once
    BigbluebuttonGetStatsWorker.perform
  end

  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonGetStatsWorker.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end

end
