require 'spec_helper'

describe BigbluebuttonUpdateRecordingsWorker do

  it "runs BigbluebuttonRails::BackgroundTasks.finish_meetings" do
    expect(BigbluebuttonRails::BackgroundTasks).to receive(:update_recordings_by_room).once
    BigbluebuttonUpdateRecordingsWorker.perform
  end

  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonUpdateRecordingsWorker.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end

end
