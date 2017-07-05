require 'spec_helper'

describe BigbluebuttonFinishMeetingsWorker do

  it "runs BigbluebuttonRails::BackgroundTasks.finish_meetings" do
    expect(BigbluebuttonRails::BackgroundTasks).to receive(:finish_meetings).once
    BigbluebuttonFinishMeetingsWorker.perform
  end

  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonFinishMeetingsWorker.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end

end
