require 'spec_helper'

describe BigbluebuttonServer do
  it "loaded correctly" do
    BigbluebuttonServer.new.should be_a_kind_of(ActiveRecord::Base)
  end

  it { should have_many(:rooms) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:salt) }
  it { should validate_presence_of(:version) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:url) }
  it { should allow_mass_assignment_of(:salt) }

  it {
    Factory.create(:bigbluebutton_server)
    should validate_uniqueness_of(:url)
  }

  it "has associated rooms" do
    server = Factory.create(:bigbluebutton_server)
    server.rooms.should be_empty

    Factory.create(:bigbluebutton_room, :server => server)
    server = BigbluebuttonServer.find(server.id)
    server.rooms.should_not be_empty
  end

  it "destroys associated rooms" do
    server = Factory.create(:bigbluebutton_server)
    Factory.create(:bigbluebutton_room, :server => server)
    Factory.create(:bigbluebutton_room, :server => server)
    expect { 
      expect { 
        server.destroy
      }.to change{ BigbluebuttonServer.count }.by(-1)
    }.to change{ BigbluebuttonRoom.count }.by(-2)
  end

  it { should ensure_length_of(:name).is_at_least(1).is_at_most(500) }
  it { should ensure_length_of(:url).is_at_most(500) }
  it { should ensure_length_of(:salt).is_at_least(1).is_at_most(500) }

  it { should allow_value('http://demo.bigbluebutton.org/bigbluebutton/api').for(:url) }
  it { should_not allow_value('').for(:url) }
  it { should_not allow_value('http://demo.bigbluebutton.org').for(:url) }
  it { should_not allow_value('demo.bigbluebutton.org/bigbluebutton/api').for(:url) }

  it { should allow_value('0.64').for(:version) }
  it { should allow_value('0.7').for(:version) }
  it { should_not allow_value('').for(:version) }
  it { should_not allow_value('0.8').for(:version) }
  it { should_not allow_value('0.6').for(:version) }

  context "has an api object" do
    let(:server) { server = Factory.build(:bigbluebutton_server) }
    it { should respond_to(:api) }
    it { server.api.should_not be_nil }
    it {
      server.save
      server.api.should_not be_nil
    }
    context "with the correct attributes" do
      let(:api) { api = BigBlueButton::BigBlueButtonApi.new(server.url, server.salt,
                                                            server.version, false) }
      it { server.api.should == api }

      # updating any of these attributes should update the api
      { :url => 'http://anotherurl.com/bigbluebutton/api',
        :salt => '12345-abcde-67890-fghijk', :version => '0.64' }.each do |k,v|
        it {
          server.send("#{k}=", v)
          server.api.send(k).should == v
        }
      end
    end
  end

  context "fetching info from bbb" do
    let(:server) { Factory.create(:bigbluebutton_server) }
    let(:room1) { Factory.create(:bigbluebutton_room, :server => server, :meeting_id => "room1") }
    let(:room2) { Factory.create(:bigbluebutton_room, :server => server, :meeting_id => "room2") }
    before {
      @api_mock = mock(BigBlueButton::BigBlueButtonApi)
      server.stub(:api).and_return(@api_mock)
    }

    # the hashes should be exactly as returned by bigbluebutton-api-ruby to be sure we are testing it right
    let(:meetings) {
      [
       { :meetingID => room1.meeting_id, :attendeePW=>"ap", :moderatorPW=>"mp", :hasBeenForciblyEnded => "false", :running => "true"},
       { :meetingID => room2.meeting_id, :attendeePW=>"pass", :moderatorPW=>"pass", :hasBeenForciblyEnded => "true", :running => "false"}
      ]
    }
    let(:hash) { 
      { :returncode => "SUCCESS",
        :meetings => meetings
      }
    }

    it { should respond_to(:fetch_meetings) }
    it { should respond_to(:meetings) }

    it "fetches meetings" do
      @api_mock.should_receive(:get_meetings).and_return(hash)
      server.fetch_meetings

      server.meetings.count.should be(2)

      server.meetings[0].running.should == true
      server.meetings[0].has_been_forcibly_ended.should == false
      server.meetings[0].room.should == room1

      server.meetings[1].running.should == false
      server.meetings[1].has_been_forcibly_ended.should == true
      server.meetings[1].room.should == room2
    end

  end


end
