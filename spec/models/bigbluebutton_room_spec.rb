require 'spec_helper'

describe BigbluebuttonRoom do
  it "loaded correctly" do
    BigbluebuttonRoom.new.should be_a_kind_of(ActiveRecord::Base)
  end

  it { should belong_to(:server) }

  it { should belong_to(:owner) }
  it { should have_db_column(:owner_id).of_type(:integer) }
  it { should have_db_column(:owner_type).of_type(:string) }
  it { should_not validate_presence_of(:owner_id) }
  it { should_not validate_presence_of(:owner_type) }

  it { should validate_presence_of(:server_id) }
  it { should validate_presence_of(:meeting_id) }
  it { should validate_presence_of(:meeting_name) }

  it { should allow_mass_assignment_of(:server_id) }
  it { should allow_mass_assignment_of(:meeting_id) }
  it { should allow_mass_assignment_of(:meeting_name) }
  it { should allow_mass_assignment_of(:attendee_password) }
  it { should allow_mass_assignment_of(:moderator_password) }
  it { should allow_mass_assignment_of(:welcome_msg) }

  it {
    Factory.create(:bigbluebutton_room)
    should validate_uniqueness_of(:meeting_id)
  }

  it {
    room = Factory.create(:bigbluebutton_room)
    room.server.should_not be_nil
  }

  it { should ensure_length_of(:meeting_id).
              is_at_least(1).is_at_most(50) }
  it { should ensure_length_of(:meeting_name).
              is_at_least(1).is_at_most(150) }
  it { should ensure_length_of(:attendee_password).
              is_at_most(50) }
  it { should ensure_length_of(:moderator_password).
              is_at_most(50) }
  it { should ensure_length_of(:welcome_msg).
              is_at_most(250) }
end
