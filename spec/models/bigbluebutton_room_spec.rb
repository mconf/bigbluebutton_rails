require 'spec_helper'

def mock_server_and_api
  @api_mock = mock(BigBlueButton::BigBlueButtonApi)
  @server_mock = mock_model(BigbluebuttonServer)
  @server_mock.stub(:api).and_return(@api_mock)
  BigbluebuttonServer.stub(:find).with(@server_mock.id.to_s).and_return(@server_mock)
end

def mocked_server
  @server_mock
end

def mocked_api
  @api_mock
end

describe BigbluebuttonRoom do
  it "loaded correctly" do
    BigbluebuttonRoom.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { Factory.create(:bigbluebutton_room) }

  it { should belong_to(:server) }

  it { should belong_to(:owner) }
  it { should have_db_column(:owner_id).of_type(:integer) }
  it { should have_db_column(:owner_type).of_type(:string) }
  it { should_not validate_presence_of(:owner_id) }
  it { should_not validate_presence_of(:owner_type) }

  it { should validate_presence_of(:server_id) }
  it { should validate_presence_of(:meeting_id) }
  it { should validate_presence_of(:name) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:attendee_password) }
  it { should allow_mass_assignment_of(:moderator_password) }
  it { should allow_mass_assignment_of(:welcome_msg) }
  it { should allow_mass_assignment_of(:server_id) }
  it { should allow_mass_assignment_of(:meeting_id) }
  it { should_not allow_mass_assignment_of(:id) }

  it { should validate_uniqueness_of(:meeting_id) }
  it { should validate_uniqueness_of(:name) }

  it {
    room = Factory.create(:bigbluebutton_room)
    room.server.should_not be_nil
  }

  it { should ensure_length_of(:meeting_id).
              is_at_least(1).is_at_most(100) }
  it { should ensure_length_of(:name).
              is_at_least(1).is_at_most(150) }
  it { should ensure_length_of(:attendee_password).
              is_at_most(50) }
  it { should ensure_length_of(:moderator_password).
              is_at_most(50) }
  it { should ensure_length_of(:welcome_msg).
              is_at_most(250) }

  # attr_readers
  [:running, :participant_count, :moderator_count, :attendees,
   :has_been_forcibly_ended, :start_time, :end_time].each do |attr|
      it { should respond_to(attr) }
  end

  context "fetching info from bbb" do
    before { mock_server_and_api }
    let(:room) { BigbluebuttonRoom.new }
    # these hashes should be exactly as returned by bigbluebutton-api-ruby to be sure we are testing it right
    let(:hash_info) { 
      { :returncode=>"SUCCESS", :meetingID=>"test_id", :attendeePW=>1234, :moderatorPW=>4321,
        :running=>"false", :hasBeenForciblyEnded=>"false", :startTime=>"null", :endTime=>"null",
        :participantCount=>0, :moderatorCount=>0, :attendees=>[], :messageKey=>{ }, :message=>{ }
      }
    }
    let(:users) { 
      [
       {:userID=>"ndw1fnaev0rj", :fullName=>"House M.D.", :role=>"MODERATOR"},
       {:userID=>"gn9e22b7ynna", :fullName=>"Dexter Morgan", :role=>"MODERATOR"},
       {:userID=>"llzihbndryc3", :fullName=>"Cameron Palmer", :role=>"VIEWER"},
       {:userID=>"rbepbovolsxt", :fullName=>"Trinity", :role=>"VIEWER"}
      ]
    }
    let(:hash_info2) { 
      { :returncode=>"SUCCESS", :meetingID=>"test_id", :attendeePW=>1234, :moderatorPW=>4321,
        :running=>"true", :hasBeenForciblyEnded=>"false", :startTime=>"Wed Apr 06 17:09:57 UTC 2011",
        :endTime=>"null", :participantCount=>4, :moderatorCount=>2,
        :attendees => users, :messageKey=>{ }, :message=>{ }
      }
    }

    it { should respond_to(:fetch_meeting_info) }
    it { should respond_to(:fetch_is_running?) }

    it "fetches is_running? when not running" do
      mocked_api.should_receive(:is_meeting_running?).with(room.meeting_id).and_return(false)
      room.server = mocked_server
      room.fetch_is_running?
      room.running.should == false
    end

    it "fetches is_running? when running" do
      mocked_api.should_receive(:is_meeting_running?).with(room.meeting_id).and_return(true)
      room.server = mocked_server
      room.fetch_is_running?
      room.running.should == true
    end

    it "fetches meeting info when the meeting is not running" do
      mocked_api.should_receive(:get_meeting_info).
        with(room.meeting_id, room.moderator_password).and_return(hash_info)
      room.server = mocked_server

      room.fetch_meeting_info
      room.running.should == false
      room.has_been_forcibly_ended.should == false
      room.participant_count.should == 0
      room.moderator_count.should == 0
      room.start_time.should == nil
      room.end_time.should == nil
      room.attendees.should == []
    end

    it "fetches meeting info when the meeting is running" do
      mocked_api.should_receive(:get_meeting_info).
        with(room.meeting_id, room.moderator_password).and_return(hash_info2)
      room.server = mocked_server

      room.fetch_meeting_info
      room.running.should == true
      room.has_been_forcibly_ended.should == false
      room.participant_count.should == 4
      room.moderator_count.should == 2
      room.start_time.should == DateTime.parse("Wed Apr 06 17:09:57 UTC 2011")
      room.end_time.should == nil

      users.each do |att|
        attendee = BigbluebuttonAttendee.new
        attendee.from_hash(att)
        room.attendees.should include(attendee)
      end
    end

  end

end
