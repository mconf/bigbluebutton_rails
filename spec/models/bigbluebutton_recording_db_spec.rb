require 'spec_helper'

describe BigbluebuttonRecording do

  # to ensure that the migration is correct
  context "db" do
    it { should have_db_column(:server_id).of_type(:integer) }
    it { should have_db_column(:room_id).of_type(:integer) }
    it { should have_db_column(:recordid).of_type(:string) }
    it { should have_db_column(:meetingid).of_type(:string) }
    it { should have_db_column(:name).of_type(:string) }
    it { should have_db_column(:published).of_type(:boolean) }
    it { should have_db_column(:start_time).of_type(:datetime) }
    it { should have_db_column(:end_time).of_type(:datetime) }
    it { should have_db_column(:available).of_type(:boolean) }
    it { should have_db_column(:description).of_type(:string) }
    it { should have_db_column(:created_at).of_type(:datetime) }
    it { should have_db_column(:updated_at).of_type(:datetime) }
    it { should have_db_index(:room_id) }
    it { should have_db_index(:recordid).unique(true) }
    it "default values" do
      room = BigbluebuttonRecording.new
      room.published.should be_false
    end
  end

end
