require 'spec_helper'

describe BigbluebuttonMeeting do

  # to ensure that the migration is correct
  context "db" do
    it { should have_db_column(:server_id).of_type(:integer) }
    it { should have_db_column(:room_id).of_type(:integer) }
    it { should have_db_column(:meetingid).of_type(:string) }
    it { should have_db_column(:name).of_type(:string) }
    it { should have_db_column(:start_time).of_type(:datetime) }
    it { should have_db_column(:running).of_type(:boolean) }
    it { should have_db_column(:record).of_type(:boolean) }
    it { should have_db_column(:creator_id).of_type(:integer) }
    it { should have_db_column(:creator_name).of_type(:string) }
    it { should have_db_index([:meetingid, :start_time]).unique(true) }
    it "default values" do
      room = BigbluebuttonRoom.new
      room.running.should be_false
      room.record.should be_false
    end
  end

end
