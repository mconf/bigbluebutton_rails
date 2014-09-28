require 'spec_helper'

describe BigbluebuttonFinishMeetings do

  it "runs BigbluebuttonRails::BackgroundTasks.finish_meetings" do
    expect(BigbluebuttonRails::BackgroundTasks).to receive(:finish_meetings).once
    BigbluebuttonFinishMeetings.perform
  end

  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonFinishMeetings.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end

end
