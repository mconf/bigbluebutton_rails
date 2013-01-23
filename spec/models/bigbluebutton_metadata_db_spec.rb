require 'spec_helper'

describe BigbluebuttonMetadata do

  # to ensure that the migration is correct
  context "db" do
    it { should have_db_column(:owner_id).of_type(:integer) }
    it { should have_db_column(:owner_type).of_type(:string) }
    it { should have_db_column(:name).of_type(:string) }
    it { should have_db_column(:content).of_type(:text) }
  end

end
