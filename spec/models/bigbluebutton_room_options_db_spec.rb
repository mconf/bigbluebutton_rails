require 'spec_helper'

describe BigbluebuttonRoomOptions do

  # to ensure that the migration is correct
  context "db" do
    it { should have_db_column(:room_id).of_type(:integer) }
    it { should have_db_column(:default_layout).of_type(:string) }
    it { should have_db_column(:created_at).of_type(:datetime) }
    it { should have_db_column(:updated_at).of_type(:datetime) }
    it { should have_db_column(:presenter_share_only).of_type(:boolean)}
    it { should have_db_column(:auto_start_video).of_type(:boolean) }
    it { should have_db_column(:auto_start_audio).of_type(:boolean) }
  end

end
