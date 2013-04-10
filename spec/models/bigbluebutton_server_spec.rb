# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonServer do
  it "loaded correctly" do
    BigbluebuttonServer.new.should be_a_kind_of(ActiveRecord::Base)
  end

  it { should have_many(:rooms).dependent(:nullify) }

  it { should have_many(:recordings).dependent(:nullify) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:salt) }
  it { should validate_presence_of(:version) }
  it { should validate_presence_of(:param) }

  [:name, :url, :salt, :version, :param].each do |attribute|
    it { should allow_mass_assignment_of(attribute) }
  end
  it { should_not allow_mass_assignment_of(:id) }

  context "uniqueness of" do
    before(:each) { FactoryGirl.create(:bigbluebutton_server) }
    it { should validate_uniqueness_of(:url) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_uniqueness_of(:param) }
  end

  it "has associated rooms" do
    server = FactoryGirl.create(:bigbluebutton_server)
    server.rooms.should be_empty

    r = FactoryGirl.create(:bigbluebutton_room, :server => server)
    server = BigbluebuttonServer.find(server.id)
    server.rooms.should == [r]
  end

  it "has associated recordings" do
    server = FactoryGirl.create(:bigbluebutton_server)
    server.rooms.should be_empty

    r = FactoryGirl.create(:bigbluebutton_recording, :server => server)
    server = BigbluebuttonServer.find(server.id)
    server.recordings.should == [r]
  end

  it { should ensure_length_of(:name).is_at_least(1).is_at_most(500) }
  it { should ensure_length_of(:url).is_at_most(500) }
  it { should ensure_length_of(:salt).is_at_least(1).is_at_most(500) }
  it { should ensure_length_of(:param).is_at_least(3) }

  context ".to_param" do
    it { should respond_to(:to_param) }
    it {
      s = FactoryGirl.create(:bigbluebutton_server)
      s.to_param.should be(s.param)
    }
  end

  context "url format" do
    it { should allow_value('http://demo.bigbluebutton.org/bigbluebutton/api').for(:url) }
    it { should_not allow_value('').for(:url) }
    it { should_not allow_value('http://demo.bigbluebutton.org').for(:url) }
    it { should_not allow_value('demo.bigbluebutton.org/bigbluebutton/api').for(:url) }
  end

  context "supported versions" do
    it { should allow_value('0.7').for(:version) }
    it { should allow_value('0.8').for(:version) }
    it { should_not allow_value('').for(:version) }
    it { should_not allow_value('0.64').for(:version) }
    it { should_not allow_value('0.6').for(:version) }
  end

  context "param format" do
    let(:msg) { I18n.t('bigbluebutton_rails.servers.errors.param_format') }
    it { should validate_format_of(:param).not_with("123 321").with_message(msg) }
    it { should validate_format_of(:param).not_with("").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab@c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab#c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab$c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab%c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ábcd").with_message(msg) }
    it { should validate_format_of(:param).not_with("-abc").with_message(msg) }
    it { should validate_format_of(:param).not_with("abc-").with_message(msg) }
    it { should validate_format_of(:param).with("_abc").with_message(msg) }
    it { should validate_format_of(:param).with("abc_").with_message(msg) }
    it { should validate_format_of(:param).with("abc") }
    it { should validate_format_of(:param).with("123") }
    it { should validate_format_of(:param).with("abc-123_d5") }
  end

  context "sets param as the downcased parameterized name if param is" do
    after :each do
      @server.save.should be_true
      @server.param.should == @server.name.downcase.parameterize
    end
    it "nil" do
      @server = FactoryGirl.build(:bigbluebutton_server, :param => nil,
                              :name => "-My Name@ _Is Odd_-")
    end
    it "empty" do
      @server = FactoryGirl.build(:bigbluebutton_server, :param => "",
                              :name => "-My Name@ _Is Odd_-")
    end
  end

  context "has an api object" do
    let(:server) { server = FactoryGirl.build(:bigbluebutton_server) }
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
        :salt => '12345-abcde-67890-fghijk', :version => '0.8' }.each do |k,v|
        it {
          server.send("#{k}=", v)
          server.api.send(k).should == v
        }
      end
    end
  end

  context "initializes" do
    let(:server) { BigbluebuttonServer.new }

    it "fetched attributes before they are fetched" do
      server.meetings.should == []
    end
  end

  it { should respond_to(:fetch_meetings) }
  it { should respond_to(:meetings) }

  context "fetching info from bbb" do
    let(:server) { FactoryGirl.create(:bigbluebutton_server) }
    let(:room1) { FactoryGirl.create(:bigbluebutton_room, :server => server, :meetingid => "room1") }
    let(:room2) { FactoryGirl.create(:bigbluebutton_room, :server => server, :meetingid => "room2") }

    # the hashes should be exactly as returned by bigbluebutton-api-ruby to be sure we are testing it right
    let(:meetings) {
      [
       { :meetingID => room1.meetingid, :attendeePW => "ap", :moderatorPW => "mp", :hasBeenForciblyEnded => false, :running => true},
       { :meetingID => room2.meetingid, :attendeePW => "pass", :moderatorPW => "pass", :hasBeenForciblyEnded => true, :running => false},
       { :meetingID => "im not in the db", :attendeePW => "pass", :moderatorPW => "pass", :hasBeenForciblyEnded => true, :running => true}
      ]
    }
    let(:hash) {
      { :returncode => true,
        :meetings => meetings
      }
    }

    before {
      @api_mock = mock(BigBlueButton::BigBlueButtonApi)
      server.stub(:api).and_return(@api_mock)
      @api_mock.should_receive(:get_meetings).and_return(hash)
      server.fetch_meetings

      # the passwords are updated during fetch_meetings
      room1.moderator_password = "mp"
      room1.attendee_password = "ap"
      room2.moderator_password = "pass"
      room2.attendee_password = "pass"
    }

    it { server.meetings.count.should be(3) }
    it { server.meetings[0].should have_same_attributes_as(room1) }
    it { server.meetings[1].should have_same_attributes_as(room2) }
    it { server.meetings[2].meetingid.should == "im not in the db" }
    it { server.meetings[2].name.should == "im not in the db" }
    it { server.meetings[2].server.should == server }
    it { server.meetings[2].attendee_password.should == "pass" }
    it { server.meetings[2].moderator_password.should == "pass" }
    it { server.meetings[2].running.should == true }
    it { server.meetings[2].new_record?.should be_true }
    it { server.meetings[2].external.should be_true }
    it { server.meetings[2].private.should be_true  }
  end

  describe "#send_publish_recordings" do
    let(:server) { FactoryGirl.create(:bigbluebutton_server) }

    it { should respond_to(:send_publish_recordings) }

    context "sends publish_recordings" do
      let(:recording1) { FactoryGirl.create(:bigbluebutton_recording, :published => false) }
      let(:recording2) { FactoryGirl.create(:bigbluebutton_recording, :published => false) }
      let(:ids) { "#{recording1.recordid},#{recording2.recordid}" }
      let(:publish) { true }
      before do
        @api_mock = mock(BigBlueButton::BigBlueButtonApi)
        server.stub(:api).and_return(@api_mock)
        @api_mock.should_receive(:publish_recordings).with(ids, publish)
      end
      before(:each) { server.send_publish_recordings(ids, publish) }
      it { BigbluebuttonRecording.find(recording1.id).published.should == true }
      it { BigbluebuttonRecording.find(recording2.id).published.should == true }
    end
  end

  describe "#send_delete_recordings" do
    let(:server) { FactoryGirl.create(:bigbluebutton_server) }

    it { should respond_to(:send_delete_recordings) }

    context "sends delete_recordings" do
      let(:ids) { "id1,id2,id3" }
      before do
        @api_mock = mock(BigBlueButton::BigBlueButtonApi)
        server.stub(:api).and_return(@api_mock)
        @api_mock.should_receive(:delete_recordings).with(ids)
      end
      it { server.send_delete_recordings(ids) }
    end
  end

  describe "#fetch_recordings" do
    let(:server) { FactoryGirl.create(:bigbluebutton_server) }
    let(:params) { { :meetingID => "id1,id2,id3" } }
    before do
      @api_mock = mock(BigBlueButton::BigBlueButtonApi)
      server.stub(:api).and_return(@api_mock)
    end

    it { should respond_to(:fetch_recordings) }

    context "calls get_recordings" do
      let(:response) { { :recordings => [1, 2] } }
      before do
        @api_mock.should_receive(:get_recordings).with(params).and_return(response)
        BigbluebuttonRecording.should_receive(:sync).with(server, response[:recordings])
      end
      it { server.fetch_recordings(params) }
    end

    context "when the response is empty" do
      let(:response) { { :recordings => [1, 2] } }
      before do
        @api_mock.should_receive(:get_recordings).with(params).and_return(nil)
        BigbluebuttonRecording.should_not_receive(:sync)
      end
      it { server.fetch_recordings(params) }
    end

    context "when the response has no :recordings element" do
      before do
        @api_mock.should_receive(:get_recordings).with(params).and_return({})
        BigbluebuttonRecording.should_not_receive(:sync)
      end
      it { server.fetch_recordings(params) }
    end

    context "works without parameters" do
      before do
        @api_mock.should_receive(:get_recordings).with({}).and_return(nil)
        BigbluebuttonRecording.should_not_receive(:sync)
      end
      it { server.fetch_recordings }
    end
  end

end
