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
    it { should have_db_column(:recorded).of_type(:boolean) }
    it { should have_db_column(:creator_id).of_type(:integer) }
    it { should have_db_column(:creator_name).of_type(:string) }
    it { should have_db_column(:create_time).of_type(:integer) }
    it { should have_db_index([:meetingid, :create_time]).unique(true) }
    it { should have_db_column(:ended).of_type(:boolean) }
    it { should have_db_column(:server_url).of_type(:string) }
    it { should have_db_column(:server_secret).of_type(:string) }
    it "default values" do
      room = BigbluebuttonMeeting.new
      room.running.should be(false)
      room.ended.should be(false)
      room.recorded.should be(false)
    end
  end

end
