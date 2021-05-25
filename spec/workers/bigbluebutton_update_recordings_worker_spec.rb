require 'spec_helper'

describe BigbluebuttonUpdateRecordingsWorker do

  context "runs BigbluebuttonRails::BackgroundTasks.finish_meetings" do
    let(:query) { BigbluebuttonRoom.where(id: 1) }
    let(:proc) { Proc.new {} }

    before {
      expect(proc).to receive(:call).once.and_return(query)
      expect(BigbluebuttonRails.configuration).to receive(:rooms_for_full_recording_sync).once.and_return(proc)
      expect(BigbluebuttonRails::BackgroundTasks).to receive(:update_recordings_by_room).once.with(query)
    }
    it { BigbluebuttonUpdateRecordingsWorker.perform }
  end

  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonUpdateRecordingsWorker.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end

end
