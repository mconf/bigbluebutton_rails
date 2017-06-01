require 'spec_helper'

describe BigbluebuttonRecordingsForRoom do

  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonRecordingsForRoom.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end

  describe "#perform" do
    let!(:room) { FactoryGirl.create(:bigbluebutton_room) }

    context "calls #fetch_recordings on the room" do
      before {
        BigbluebuttonRoom.stub(:find).and_return(room)
        expect(room).to receive(:fetch_recordings).once
      }
      it { BigbluebuttonRecordingsForRoom.perform(room.id) }
    end

    context "if there are still tries left" do
      before {
        BigbluebuttonRoom.stub(:find).and_return(room)
        room.stub(:fetch_recordings)
        expect(Resque).to receive(:enqueue_in)
                           .with(5.minutes, ::BigbluebuttonRecordingsForRoom, room.id, 0)
                           .once
      }
      it { BigbluebuttonRecordingsForRoom.perform(room.id, 1) }
    end

    context "if there are no more tries left" do
      before {
        BigbluebuttonRoom.stub(:find).and_return(room)
        room.stub(:fetch_recordings)
        expect(Resque).not_to receive(:enqueue_in)
      }
      it { BigbluebuttonRecordingsForRoom.perform(room.id, 0) }
    end

    context "if the room id is not found" do
      before {
        BigbluebuttonRoom.stub(:find).and_return(nil)
        expect(room).not_to receive(:fetch_recordings)
        expect(Resque).not_to receive(:enqueue_in)
      }
      it { BigbluebuttonRecordingsForRoom.perform(room.id) }
    end
  end
end
