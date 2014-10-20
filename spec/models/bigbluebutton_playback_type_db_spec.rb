require 'spec_helper'

describe BigbluebuttonPlaybackType do

  # to ensure that the migration is correct
  context "db" do
    it { should have_db_column(:identifier).of_type(:string) }
    it { should have_db_column(:visible).of_type(:boolean) }
    it { should have_db_column(:created_at).of_type(:datetime) }
    it { should have_db_column(:updated_at).of_type(:datetime) }
  end

end
