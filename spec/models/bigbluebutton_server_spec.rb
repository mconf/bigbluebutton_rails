require 'spec_helper'

describe BigbluebuttonServer do
  it "loaded correctly" do
    BigbluebuttonServer.new.should be_a_kind_of(ActiveRecord::Base)
  end

  it { should have_many(:rooms) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:salt) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:url) }
  it { should allow_mass_assignment_of(:salt) }

  it {
    Factory.create(:bigbluebutton_server)
    should validate_uniqueness_of(:url)
  }

  it {
    server = Factory.create(:bigbluebutton_server)
    server.rooms.should be_empty

    Factory.create(:bigbluebutton_room, :server => server)
    server = BigbluebuttonServer.find(server.id)
    server.rooms.should_not be_empty
  }

  it { should ensure_length_of(:name).
              is_at_least(1).is_at_most(500) }
  it { should ensure_length_of(:url).
              is_at_most(500) }
  it { should ensure_length_of(:salt).
              is_at_least(1).is_at_most(500) }

  it { should allow_value('http://demo.bigbluebutton.org/bigbluebutton/api').for(:url) }
  it { should_not allow_value('').for(:url) }
  it { should_not allow_value('http://demo.bigbluebutton.org').for(:url) }
  it { should_not allow_value('demo.bigbluebutton.org/bigbluebutton/api').for(:url) }
end
