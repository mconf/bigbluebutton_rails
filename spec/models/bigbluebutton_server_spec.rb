require 'spec_helper'

describe BigbluebuttonServer do
  it "loaded correctly" do
    BigbluebuttonServer.new.should be_a_kind_of(ActiveRecord::Base)
  end

  it { should have_many(:bigbluebutton_rooms) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:salt) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:url) }
  it { should allow_mass_assignment_of(:salt) }

  #it {
  #  Factory.create(:bigbluebutton_server)
  #  should validate_uniqueness_of(:url)
  #}
end
