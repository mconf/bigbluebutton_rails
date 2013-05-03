# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonRoom do
  it "loaded correctly" do
    BigbluebuttonRoom.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_room) }

  it { should belong_to(:server) }
  it { should_not validate_presence_of(:server_id) }

  it { should belong_to(:owner) }
  it { should_not validate_presence_of(:owner_id) }
  it { should_not validate_presence_of(:owner_type) }

  it { should have_many(:recordings).dependent(:nullify) }

  it { should have_many(:metadata).dependent(:destroy) }

  it { should validate_presence_of(:meetingid) }
  it { should validate_uniqueness_of(:meetingid) }
  it { should ensure_length_of(:meetingid).is_at_least(1).is_at_most(100) }

  it { should validate_presence_of(:voice_bridge) }
  it { should validate_uniqueness_of(:voice_bridge) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should ensure_length_of(:name).is_at_least(1).is_at_most(150) }

  it { should validate_presence_of(:param) }
  it { should validate_uniqueness_of(:param) }
  it { should ensure_length_of(:param).is_at_least(1) }

  it { should be_boolean(:private) }

  it { should be_boolean(:record) }

  it { should validate_presence_of(:duration) }
  it { should validate_numericality_of(:duration).only_integer }
  it { should_not allow_value(-1).for(:duration) }
  it { should allow_value(0).for(:duration) }
  it { should allow_value(1).for(:duration) }

  it { should ensure_length_of(:attendee_password).is_at_most(16) }

  it { should ensure_length_of(:moderator_password).is_at_most(16) }

  it { should ensure_length_of(:welcome_msg).is_at_most(250) }

  it { should accept_nested_attributes_for(:metadata).allow_destroy(true) }

  [:name, :server_id, :meetingid, :attendee_password,
   :moderator_password, :welcome_msg, :owner, :private, :logout_url,
   :dial_number, :voice_bridge, :max_participants, :owner_id,
   :owner_type, :param, :metadata_attributes].
    each do |attribute|
    it { should allow_mass_assignment_of(attribute) }
  end
  it { should_not allow_mass_assignment_of(:id) }

  # attr_accessors
  [:running, :participant_count, :moderator_count, :attendees,
   :has_been_forcibly_ended, :start_time, :end_time, :external,
   :server, :request_headers, :record, :duration].each do |attr|
    it { should respond_to(attr) }
    it { should respond_to("#{attr}=") }
  end

  context ".to_param" do
    it { should respond_to(:to_param) }
    it {
      r = FactoryGirl.create(:bigbluebutton_room)
      r.to_param.should be(r.param)
    }
  end

  it { should respond_to(:is_running?) }

  describe "#user_role" do
    let(:room) { FactoryGirl.build(:bigbluebutton_room, :moderator_password => "mod", :attendee_password => "att") }
    it { should respond_to(:user_role) }
    it { room.user_role({ :password => room.moderator_password }).should == :moderator }
    it { room.user_role({ :password => room.attendee_password }).should == :attendee }
    it { room.user_role({ :password => "wrong" }).should == nil }
    it { room.user_role({ :password => nil }).should == nil }
    it { room.user_role({ :not_password => "any" }).should == nil }
  end

  describe "#instance_variables_compare" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }
    let(:room2) { BigbluebuttonRoom.last }
    it { should respond_to(:instance_variables_compare) }
    it { room.instance_variables_compare(room2).should be_empty }
    it "compares instance variables" do
      room2.running = !room.running
      room.instance_variables_compare(room2).should_not be_empty
      room.instance_variables_compare(room2).should include(:@running)
    end
    it "ignores attributes" do
      room2.private = !room.private
      room.instance_variables_compare(room2).should be_empty
    end
  end

  describe "#attr_equal?" do
    before { FactoryGirl.create(:bigbluebutton_room) }
    let(:room) { BigbluebuttonRoom.last }
    let(:room2) { BigbluebuttonRoom.last }
    it { should respond_to(:attr_equal?) }
    it { room.attr_equal?(room2).should be_true }
    it "differentiates instance variables" do
      room2.running = !room.running
      room.attr_equal?(room2).should be_false
    end
    it "differentiates attributes" do
      room2.private = !room.private
      room.attr_equal?(room2).should be_false
    end
    it "differentiates objects" do
      room2 = room.dup
      room.attr_equal?(room2).should be_false
    end
  end

  context "initializes" do
    let(:room) { BigbluebuttonRoom.new }

    it "fetched attributes before they are fetched" do
      room.participant_count.should be(0)
      room.moderator_count.should be(0)
      room.running.should be_false
      room.has_been_forcibly_ended.should be_false
      room.start_time.should be_nil
      room.end_time.should be_nil
      room.attendees.should eql([])
      room.request_headers.should == {}
    end

    context "meetingid" do
      it { room.meetingid.should_not be_nil }
      it {
        b = BigbluebuttonRoom.new(:meetingid => "user defined")
        b.meetingid.should == "user defined"
      }
    end

    context "voice_bridge" do
      it {
        b = BigbluebuttonRoom.new(:voice_bridge => "user defined")
        b.voice_bridge.should == "user defined"
      }
      context "with a random value" do
        it { room.voice_bridge.should_not be_nil }
        it { room.voice_bridge.should =~ /7[0-9]{4}/ }
        it "tries to randomize 10 times if voice_bridge already exists" do
          room = FactoryGirl.create(:bigbluebutton_room, :voice_bridge => "70000")
          BigbluebuttonRoom.stub!(:find_by_voice_bridge).and_return(room)
          SecureRandom.should_receive(:random_number).exactly(10).and_return(0000)
          room2 = BigbluebuttonRoom.new # triggers the random_number calls
          room2.voice_bridge.should == "70000"
        end
      end
    end
  end

  context "#param format" do
    let(:msg) { I18n.t('bigbluebutton_rails.rooms.errors.param_format') }
    it { should validate_format_of(:param).not_with("123 321").with_message(msg) }
    it { should validate_format_of(:param).not_with("").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab@c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab#c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab$c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab%c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ábcd").with_message(msg) }
    it { should validate_format_of(:param).not_with("-abc").with_message(msg) }
    it { should validate_format_of(:param).not_with("abc-").with_message(msg) }
    it { should validate_format_of(:param).not_with("-").with_message(msg) }
    it { should validate_format_of(:param).with("_abc").with_message(msg) }
    it { should validate_format_of(:param).with("abc_").with_message(msg) }
    it { should validate_format_of(:param).with("abc") }
    it { should validate_format_of(:param).with("123") }
    it { should validate_format_of(:param).with("1") }
    it { should validate_format_of(:param).with("a") }
    it { should validate_format_of(:param).with("_") }
    it { should validate_format_of(:param).with("abc-123_d5") }
  end

  context "sets param as the downcased parameterized name if param is" do
    after :each do
      @room.save.should be_true
      @room.param.should == @room.name.downcase.parameterize
    end
    it "nil" do
      @room = FactoryGirl.build(:bigbluebutton_room, :param => nil,
                            :name => "-My Name@ _Is Odd_-")
    end
    it "empty" do
      @room = FactoryGirl.build(:bigbluebutton_room, :param => "",
                            :name => "-My Name@ _Is Odd_-")
    end
  end

  context "when room set to private" do
    context "sets passwords that are not yet defined" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :private => false, :moderator_password => nil, :attendee_password => nil) }
      before(:each) { room.update_attributes(:private => true) }
      it { room.moderator_password.should_not be_nil }
      it { room.attendee_password.should_not be_nil }
    end

    context "only sets the passwords if the room was public before" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :private => true, :moderator_password => "123", :attendee_password => "321") }
      before(:each) { room.update_attributes(:private => true) }
      it { room.moderator_password.should == "123" }
      it { room.attendee_password.should == "321" }
    end
  end

  context "using the api" do
    before { mock_server_and_api }
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }

    describe "#fetch_is_running?" do

      it { should respond_to(:fetch_is_running?) }

      context "fetches is_running? when not running" do
        before {
          mocked_api.should_receive(:is_meeting_running?).with(room.meetingid).and_return(false)
          room.should_receive(:require_server)
          room.server = mocked_server
        }
        before(:each) { room.fetch_is_running? }
        it { room.running.should == false }
        it { room.is_running?.should == false }
      end

      context "fetches is_running? when running" do
        before {
          mocked_api.should_receive(:is_meeting_running?).with(room.meetingid).and_return(true)
          room.should_receive(:require_server)
          room.server = mocked_server
        }
        before(:each) { room.fetch_is_running? }
        it { room.running.should == true }
        it { room.is_running?.should == true }
      end

    end

    describe "#fetch_meeting_info" do

      # these hashes should be exactly as returned by bigbluebutton-api-ruby to be sure we are testing it right
      let(:hash_info) {
        { :returncode=>true, :meetingID=>"test_id", :attendeePW=>"1234", :moderatorPW=>"4321",
          :running=>false, :hasBeenForciblyEnded=>false, :startTime=>nil, :endTime=>nil,
          :participantCount=>0, :moderatorCount=>0, :attendees=>[], :messageKey=>"", :message=>""
        }
      }
      let(:users) {
        [
         {:userID=>"ndw1fnaev0rj", :fullName=>"House M.D.", :role=>:moderator},
         {:userID=>"gn9e22b7ynna", :fullName=>"Dexter Morgan", :role=>:moderator},
         {:userID=>"llzihbndryc3", :fullName=>"Cameron Palmer", :role=>:viewer},
         {:userID=>"rbepbovolsxt", :fullName=>"Trinity", :role=>:viewer}
        ]
      }
      let(:hash_info2) {
        { :returncode=>true, :meetingID=>"test_id", :attendeePW=>"1234", :moderatorPW=>"4321",
          :running=>true, :hasBeenForciblyEnded=>false, :startTime=>DateTime.parse("Wed Apr 06 17:09:57 UTC 2011"),
          :endTime=>nil, :participantCount=>4, :moderatorCount=>2,
          :attendees=>users, :messageKey=>{ }, :message=>{ }
        }
      }

      it { should respond_to(:fetch_meeting_info) }

      context "fetches meeting info when the meeting is not running" do
        before {
          mocked_api.should_receive(:get_meeting_info).
            with(room.meetingid, room.moderator_password).and_return(hash_info)
          room.should_receive(:require_server)
          room.server = mocked_server
        }
        before(:each) { room.fetch_meeting_info }
        it { room.running.should == false }
        it { room.has_been_forcibly_ended.should == false }
        it { room.participant_count.should == 0 }
        it { room.moderator_count.should == 0 }
        it { room.start_time.should == nil }
        it { room.end_time.should == nil }
        it { room.attendees.should == [] }
      end

      context "fetches meeting info when the meeting is running" do
        before {
          mocked_api.should_receive(:get_meeting_info).
            with(room.meetingid, room.moderator_password).and_return(hash_info2)
          room.should_receive(:require_server)
          room.server = mocked_server
        }
        before(:each) { room.fetch_meeting_info }
        it { room.running.should == true }
        it { room.has_been_forcibly_ended.should == false }
        it { room.participant_count.should == 4 }
        it { room.moderator_count.should == 2 }
        it { room.start_time.should == DateTime.parse("Wed Apr 06 17:09:57 UTC 2011") }
        it { room.end_time.should == nil }
        it {
          users.each do |att|
            attendee = BigbluebuttonAttendee.new
            attendee.from_hash(att)
            room.attendees.should include(attendee)
          end
        }
      end

    end

    describe "#send_end" do
      it { should respond_to(:send_end) }

      it "send end_meeting" do
        mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_password)
        room.should_receive(:require_server)
        room.server = mocked_server
        room.send_end
      end
    end

    describe "#send_create" do
      let(:attendee_password) { Forgery(:basic).password }
      let(:moderator_password) { Forgery(:basic).password }
      let(:hash_create) {
        {
          :returncode => "SUCCESS", :meetingID => "test_id",
          :attendeePW => attendee_password, :moderatorPW => moderator_password,
          :hasBeenForciblyEnded => "false", :messageKey => {}, :message => {}
        }
      }
      before {
        room.update_attributes(:welcome_msg => "Anything")
        FactoryGirl.create(:bigbluebutton_room_metadata, :owner => room)
        FactoryGirl.create(:bigbluebutton_room_metadata, :owner => room)

        mocked_api.should_receive(:"request_headers=").any_number_of_times.with({})
      }

      it { should respond_to(:send_create) }

      context "calls #default_welcome_msg if welcome_msg is" do
        before do
          room.should_receive(:default_welcome_message).and_return("Hi!")
          mocked_api.should_receive(:create_meeting)
            .with(anything, anything, hash_including(:welcome  => "Hi!"))
          room.stub(:select_server).and_return(mocked_server)
          room.server = mocked_server
        end

        context "nil" do
          before { room.welcome_msg = nil }
          it { room.send_create }
        end
        context "empty" do
          before { room.welcome_msg = "" }
          it { room.send_create }
        end
      end

      context "sends create_meeting" do

        context "for a stored room" do
          before do
            mocked_api.should_receive(:create_meeting)
              .with(room.name, room.meetingid, get_create_params(room))
              .and_return(hash_create)
            room.stub(:select_server).and_return(mocked_server)
            room.server = mocked_server
            room.send_create
          end
          it { room.attendee_password.should be(attendee_password) }
          it { room.moderator_password.should be(moderator_password) }
          it { room.changed?.should be_false }
        end

        context "for a new record" do
          let(:new_room) { FactoryGirl.build(:bigbluebutton_room) }
          before do
            mocked_api.should_receive(:create_meeting)
              .with(new_room.name, new_room.meetingid, get_create_params(new_room))
              .and_return(hash_create)
            new_room.stub(:select_server).and_return(mocked_server)
            new_room.server = mocked_server
            new_room.send_create
          end
          it { new_room.attendee_password.should be(attendee_password) }
          it { new_room.moderator_password.should be(moderator_password) }
          it("and do not save the record") { new_room.new_record?.should be_true }
        end

        context "passing the user's name and id" do
          let(:user) { FactoryGirl.build(:user) }
          before do
            mocked_api.should_receive(:create_meeting)
              .with(room.name, room.meetingid, get_create_params(room, user.name, user.id))
              .and_return(hash_create)
            room.stub(:select_server).and_return(mocked_server)
            room.server = mocked_server
            room.send_create(user.name, user.id)
          end
          it { room.attendee_password.should be(attendee_password) }
          it { room.moderator_password.should be(moderator_password) }
          it { room.changed?.should be_false }
        end
      end

      context "generates a meetingid if nil" do
        let(:new_id) { "new id" }
        before {
          room.meetingid = nil
          room.stub(:select_server).and_return(mocked_server)
          room.server = mocked_server
        }
        it "before calling create" do
          room.should_receive(:unique_meetingid).and_return(new_id)
          mocked_api.should_receive(:create_meeting)
            .with(room.name, new_id, get_create_params(room))
          room.send_create
        end
      end

      context "uses #full_logout_url when set" do
        before do
          room.full_logout_url = "full-version-of-logout-url"
          hash = get_create_params(room).merge({ :logoutURL => "full-version-of-logout-url" })
          mocked_api.should_receive(:create_meeting).
            with(room.name, room.meetingid, hash).and_return(hash_create)
          room.stub(:select_server).and_return(mocked_server)
          room.server = mocked_server
        end
        it { room.send_create }
      end

      context "selects and requires a server" do
        let(:another_server) { FactoryGirl.create(:bigbluebutton_server) }

        context "and saves the result" do
          before do
            room.should_receive(:select_server).and_return(another_server)
            room.should_receive(:require_server)
            room.should_receive(:do_create_meeting)
            room.server = mocked_server
            room.send_create
          end
          it { BigbluebuttonRoom.find(room.id).server_id.should == another_server.id }
        end

        context "and does not save when is a new record" do
          let(:new_room) { FactoryGirl.build(:bigbluebutton_room) }
          before do
            new_room.should_receive(:select_server).and_return(another_server)
            new_room.should_receive(:require_server)
            new_room.should_receive(:do_create_meeting).and_return(nil)
            new_room.should_not_receive(:save)
            new_room.server = mocked_server
            new_room.send_create
          end
          it { new_room.new_record?.should be_true }
        end
      end

      context "sets the request headers in the server api" do
        before do
          mocked_api.should_receive(:create_meeting).with(anything, anything, anything)
          room.stub(:select_server).and_return(mocked_server)
          room.server = mocked_server
          room.request_headers = { :anything => "anything" }
          mocked_api.should_receive(:"request_headers=").once.with(room.request_headers)
        end
        it { room.send_create }
      end

    end # #send_create

    describe "#join_url" do
      let(:username) { Forgery(:name).full_name }

      it { should respond_to(:join_url) }

      context do
        before { room.should_receive(:require_server) }

        it "with moderator role" do
          mocked_api.should_receive(:join_meeting_url).
            with(room.meetingid, username, room.moderator_password)
          room.server = mocked_server
          room.join_url(username, :moderator)
        end

        it "with attendee role" do
          mocked_api.should_receive(:join_meeting_url).
            with(room.meetingid, username, room.attendee_password)
          room.server = mocked_server
          room.join_url(username, :attendee)
        end

        it "without a role" do
          mocked_api.should_receive(:join_meeting_url).
            with(room.meetingid, username, 'pass')
          room.server = mocked_server
          room.join_url(username, nil, 'pass')
        end
      end
    end

  end

  context "validates passwords" do
    context "for private rooms" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :private => true) }
      it { room.should_not allow_value('').for(:moderator_password) }
      it { room.should_not allow_value('').for(:attendee_password) }
    end

    context "for public rooms" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :private => false) }
      it { room.should allow_value('').for(:moderator_password) }
      it { room.should allow_value('').for(:attendee_password) }
    end
  end

  describe "#add_domain_to_logout_url" do
    context "when logout_url has a path only" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :logout_url => '/only/path') }
      before(:each) { room.add_domain_to_logout_url("HTTP://", "test.com:80") }
      it { room.full_logout_url.should == "http://test.com:80/only/path" }
      it { room.logout_url.should == "/only/path" }
      it { BigbluebuttonRoom.find(room.id).logout_url.should == "/only/path" }
    end

    context "when logout_url has a path and domain" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :logout_url => 'other.com/only/path') }
      before(:each) { room.add_domain_to_logout_url("HTTP://", "test.com:80") }
      it { room.full_logout_url.should == "http://other.com/only/path" }
      it { room.logout_url.should == "other.com/only/path" }
      it { BigbluebuttonRoom.find(room.id).logout_url.should == "other.com/only/path" }
    end

    context "when logout_url has a path, domain and protocol" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :logout_url => 'HTTPS://other.com/only/path') }
      before(:each) { room.add_domain_to_logout_url("HTTP://", "test.com:80") }
      it { room.full_logout_url.should == "https://other.com/only/path" }
      it { room.logout_url.should == "HTTPS://other.com/only/path" }
      it { BigbluebuttonRoom.find(room.id).logout_url.should == "HTTPS://other.com/only/path" }
    end

    context "does nothing if logout_url is nil" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :logout_url => nil) }
      before(:each) { room.add_domain_to_logout_url("HTTP://", "test.com:80") }
      it { room.full_logout_url.should be_nil }
      it { room.logout_url.should be_nil }
      it { BigbluebuttonRoom.find(room.id).logout_url.should be_nil }
    end
  end

  describe "#create_meeting" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }
    let(:user) { FactoryGirl.build(:user) }
    before { room.should_receive(:fetch_is_running?) }

    context "when the conference is running" do
      before {
        room.should_receive(:is_running?).and_return(true)
      }
      subject { room.create_meeting(user.name) }
      it { should be_false }
    end

    context "when the conference is not running" do
      before {
        room.should_receive(:is_running?).and_return(false)
        room.should_receive(:send_create).with(user.name, user.id)
      }
      subject { room.create_meeting(user.name, user.id) }
      it { should be_true }
    end

    context "when the arg 'request' is informed" do
      let(:request) { stub(ActionDispatch::Request) }
      before {
        request.stub!(:protocol).and_return("HTTP://")
        request.stub!(:host_with_port).and_return("test.com:80")
        room.should_receive(:add_domain_to_logout_url).with("HTTP://", "test.com:80")
        room.should_receive(:is_running?).and_return(false)
        room.should_receive(:send_create)
      }
      subject { room.create_meeting(user.name, user.id, request) }
      it { should be_true }
    end
  end

  describe "#full_logout_url" do
    subject { BigbluebuttonRoom.new }
    it { should respond_to(:full_logout_url) }
    it { should respond_to(:"full_logout_url=") }
  end

  describe "#require_server" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }
    it { should respond_to(:require_server) }

    context "throws exception when the room has no server associated" do
      before { room.server = nil }
      it {
        lambda {
          room.send(:require_server)
        }.should raise_error(BigbluebuttonRails::ServerRequired)
      }
    end

    context "does nothing if the room has a server associated" do
      before { room.server = FactoryGirl.create(:bigbluebutton_server) }
      it {
        lambda {
          room.send(:require_server)
        }.should_not raise_error(BigbluebuttonRails::ServerRequired)
      }
    end
  end

  describe "#select_server" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room, :server => nil) }
    it { should respond_to(:select_server) }

    context "selects the server with less rooms" do
      before {
        BigbluebuttonServer.destroy_all
        s1 = FactoryGirl.create(:bigbluebutton_server)
        @s2 = FactoryGirl.create(:bigbluebutton_server)
        3.times{ FactoryGirl.create(:bigbluebutton_room, :server => s1) }
        2.times{ FactoryGirl.create(:bigbluebutton_room, :server => @s2) }
      }
      it { room.send(:select_server).should == @s2 }
    end

    context "returns nil of there are no servers" do
      before(:each) { BigbluebuttonServer.destroy_all }
      it { room.send(:select_server).should == nil }
    end
  end

  describe "#get_metadata_for_create" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room, :server => nil) }
    before {
      @m1 = FactoryGirl.create(:bigbluebutton_room_metadata, :owner => room)
      @m2 = FactoryGirl.create(:bigbluebutton_room_metadata, :owner => room)
    }
    it {
      result = { "meta_#{@m1.name}" => @m1.content, "meta_#{@m2.name}" => @m2.content }
      room.send(:get_metadata_for_create).should == result
    }
  end

end

def get_create_params(room, username=nil, userid=nil)
  params = {
    :moderatorPW => room.moderator_password,
    :attendeePW => room.attendee_password,
    :welcome  => room.welcome_msg,
    :dialNumber => room.dial_number,
    :logoutURL => room.logout_url,
    :maxParticipants => room.max_participants,
    :voiceBridge => room.voice_bridge,
    :record => room.record,
    :duration => room.duration
  }
  room.metadata.each { |meta| params["meta_#{meta.name}"] = meta.content }
  params.merge!({ "meta_bbbrails-user-id" => userid }) unless userid.nil?
  params.merge!({ "meta_bbbrails-user-name" => username }) unless username.nil?
  params
end
