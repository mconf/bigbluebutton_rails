require 'spec_helper'

describe BigbluebuttonServer do

  # to ensure that the migration is correct
  context "db" do
    it { should have_db_column(:name).of_type(:string) }
    it { should have_db_column(:url).of_type(:string) }
    it { should have_db_column(:secret).of_type(:string) }
    it { should have_db_column(:version).of_type(:string) }
    it { should have_db_column(:slug).of_type(:string) }
    it { should have_db_column(:created_at).of_type(:datetime) }
    it { should have_db_column(:updated_at).of_type(:datetime) }
  end

end
