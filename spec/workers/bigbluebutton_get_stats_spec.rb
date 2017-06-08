require 'spec_helper'

describe BigbluebuttonGetStats do

  it "runs BigbluebuttonRails::BackgroundTasks.get_stats" do
    expect(BigbluebuttonRails::BackgroundTasks).to receive(:get_stats).once
    BigbluebuttonGetStats.perform
  end

  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonGetStats.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end

end
