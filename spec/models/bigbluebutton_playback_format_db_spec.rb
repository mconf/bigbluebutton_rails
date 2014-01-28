require 'spec_helper'

describe BigbluebuttonPlaybackFormat do

  # to ensure that the migration is correct
  context "db" do
    it { should have_db_column(:recording_id).of_type(:integer) }
    it { should have_db_column(:format_type).of_type(:string) }
    it { should have_db_column(:url).of_type(:string) }
    it { should have_db_column(:length).of_type(:integer) }
    it { should have_db_column(:created_at).of_type(:datetime) }
    it { should have_db_column(:updated_at).of_type(:datetime) }
  end

end
