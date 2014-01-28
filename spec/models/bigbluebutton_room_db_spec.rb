require 'spec_helper'

describe BigbluebuttonRoom do

  # to ensure that the migration is correct
  context "db" do
    it { should have_db_column(:server_id).of_type(:integer) }
    it { should have_db_column(:owner_id).of_type(:integer) }
    it { should have_db_column(:owner_type).of_type(:string) }
    it { should have_db_column(:meetingid).of_type(:string) }
    it { should have_db_column(:name).of_type(:string) }
    it { should have_db_column(:attendee_password).of_type(:string) }
    it { should have_db_column(:moderator_password).of_type(:string) }
    it { should have_db_column(:welcome_msg).of_type(:string) }
    it { should have_db_column(:dial_number).of_type(:string) }
    it { should have_db_column(:logout_url).of_type(:string) }
    it { should have_db_column(:voice_bridge).of_type(:string) }
    it { should have_db_column(:max_participants).of_type(:integer) }
    it { should have_db_column(:private).of_type(:boolean) }
    it { should have_db_column(:external).of_type(:boolean) }
    it { should have_db_column(:param).of_type(:string) }
    it { should have_db_column(:record).of_type(:boolean) }
    it { should have_db_column(:duration).of_type(:integer) }
    it { should have_db_column(:created_at).of_type(:datetime) }
    it { should have_db_column(:updated_at).of_type(:datetime) }
    it { should have_db_index(:server_id) }
    it { should have_db_index(:meetingid).unique(true) }
    it { should have_db_index(:voice_bridge).unique(true) }
    it "default values" do
      room = BigbluebuttonRoom.new
      room.private.should be_false
      room.external.should be_false
      room.meetingid.should_not be_nil
    end
  end

end
