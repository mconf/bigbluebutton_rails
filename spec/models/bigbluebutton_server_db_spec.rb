require 'spec_helper'

describe BigbluebuttonServer do

  # to ensure that the migration is correct
  context "db" do
    it { should have_db_column(:name).of_type(:string) }
    it { should have_db_column(:url).of_type(:string) }
    it { should have_db_column(:salt).of_type(:string) }
    it { should have_db_column(:version).of_type(:string) }
    it { should have_db_column(:param).of_type(:string) }
  end

end
