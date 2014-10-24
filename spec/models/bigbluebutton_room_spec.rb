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

  it { should have_one(:room_options).dependent(:destroy) }

  it { should delegate(:default_layout).to(:room_options) }
  it { should delegate(:"default_layout=").to(:room_options) }

  it { should delegate(:presenter_share_only).to(:room_options) }
  it { should delegate(:"presenter_share_only=").to(:room_options) }

  it { should delegate(:auto_start_video).to(:room_options) }
  it { should delegate(:"auto_start_video=").to(:room_options) }

  it { should delegate(:auto_start_audio).to(:room_options) }
  it { should delegate(:"auto_start_audio=").to(:room_options) }

  it { should delegate(:get_available_layouts).to(:room_options) }

  it { should validate_presence_of(:meetingid) }
  it { should validate_uniqueness_of(:meetingid) }
  it { should ensure_length_of(:meetingid).is_at_least(1).is_at_most(100) }

  it { should validate_presence_of(:voice_bridge) }
  it { should validate_uniqueness_of(:voice_bridge) }

  it { should validate_presence_of(:name) }
  it { should ensure_length_of(:name).is_at_least(1).is_at_most(150) }

  it { should validate_presence_of(:param) }
  it { should validate_uniqueness_of(:param) }
  it { should ensure_length_of(:param).is_at_least(1) }

  it { should be_boolean(:private) }

  it { should be_boolean(:record_meeting) }

  it { should validate_presence_of(:duration) }
  it { should validate_numericality_of(:duration).only_integer }
  it { should_not allow_value(-1).for(:duration) }
  it { should allow_value(0).for(:duration) }
  it { should allow_value(1).for(:duration) }

  it { should ensure_length_of(:attendee_key).is_at_most(16) }

  it { should ensure_length_of(:moderator_key).is_at_most(16) }

  it { should ensure_length_of(:welcome_msg).is_at_most(250) }

  it { should accept_nested_attributes_for(:metadata).allow_destroy(true) }

  # attr_accessors
  [:running, :participant_count, :moderator_count, :attendees,
   :has_been_forcibly_ended, :start_time, :end_time, :external,
   :server, :request_headers, :record_meeting, :duration].each do |attr|
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
    let(:room) { FactoryGirl.build(:bigbluebutton_room, :moderator_key => "mod", :attendee_key => "att") }
    it { should respond_to(:user_role) }
    it { room.user_role({ :key => room.moderator_key }).should == :moderator }
    it { room.user_role({ :key => room.attendee_key }).should == :attendee }
    it { room.user_role({ :key => "wrong" }).should == nil }
    it { room.user_role({ :key => nil }).should == nil }
    it { room.user_role({ :not_key => "any" }).should == nil }
    it { room.user_role({ }).should == nil }
    it { room.user_role(nil).should == nil }
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
    it { room.attr_equal?(room2).should be_truthy }
    it "differentiates instance variables" do
      room2.running = !room.running
      room.attr_equal?(room2).should be_falsey
    end
    it "differentiates attributes" do
      room2.private = !room.private
      room.attr_equal?(room2).should be_falsey
    end
    it "differentiates objects" do
      room2 = room.dup
      room.attr_equal?(room2).should be_falsey
    end
  end

  context "initializes" do
    let(:room) { BigbluebuttonRoom.new }

    it "fetched attributes before they are fetched" do
      room.participant_count.should be(0)
      room.moderator_count.should be(0)
      room.running.should be_falsey
      room.has_been_forcibly_ended.should be_falsey
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
          BigbluebuttonRoom.stub(:find_by_voice_bridge).and_return(room)
          SecureRandom.should_receive(:random_number).exactly(10).and_return(0000)
          room2 = BigbluebuttonRoom.new # triggers the random_number calls
          room2.voice_bridge.should == "70000"
        end
      end
    end
  end

  describe "#room_options" do
    it "is created when the room is created" do
      room = FactoryGirl.create(:bigbluebutton_room)
      room.room_options.should_not be_nil
      room.room_options.should be_an_instance_of(BigbluebuttonRoomOptions)
      room.room_options.room.should eql(room)
    end

    context "if it was not created, is built when accessed" do
      before(:each) {
        @room = FactoryGirl.create(:bigbluebutton_room)
        @room.room_options.destroy
        @room.reload
        @room.room_options # access it so the new obj is created
      }
      it { @room.room_options.should_not be_nil }
      it("is not promptly saved") {
        @room.room_options.new_record?.should be_truthy
      }
      it("is saved when the room is saved") {
        @room.save!
        @room.reload
        @room.room_options.new_record?.should be_falsey
      }
    end
  end

  context "#param format" do
    let(:msg) { I18n.t('bigbluebutton_rails.rooms.errors.param_format') }
    it { should_not allow_value("123 321").for(:param).with_message(msg) }
    it { should_not allow_value("").for(:param).with_message(msg) }
    it { should_not allow_value("ab@c").for(:param).with_message(msg) }
    it { should_not allow_value("ab#c").for(:param).with_message(msg) }
    it { should_not allow_value("ab$c").for(:param).with_message(msg) }
    it { should_not allow_value("ab%c").for(:param).with_message(msg) }
    it { should_not allow_value("ábcd").for(:param).with_message(msg) }
    it { should_not allow_value("-abc").for(:param).with_message(msg) }
    it { should_not allow_value("abc-").for(:param).with_message(msg) }
    it { should_not allow_value("-").for(:param).with_message(msg) }
    it { should allow_value("_abc").for(:param).with_message(msg) }
    it { should allow_value("abc_").for(:param).with_message(msg) }
    it { should allow_value("abc").for(:param).with_message(msg) }
    it { should allow_value("123").for(:param).with_message(msg) }
    it { should allow_value("1").for(:param).with_message(msg) }
    it { should allow_value("a").for(:param).with_message(msg) }
    it { should allow_value("_").for(:param).with_message(msg) }
    it { should allow_value("abc-123_d5").for(:param).with_message(msg) }
  end

  context "sets param as the downcased parameterized name if param is" do
    after :each do
      @room.save.should be_truthy
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
    context "sets keys that are not yet defined" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :private => false, :moderator_key => nil, :attendee_key => nil) }
      before(:each) { room.update_attributes(:private => true) }
      it { room.moderator_key.should_not be_nil }
      it { room.attendee_key.should_not be_nil }
    end

    context "only sets the keys if the room was public before" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :private => true, :moderator_key => "123", :attendee_key => "321") }
      before(:each) { room.update_attributes(:private => true) }
      it { room.moderator_key.should == "123" }
      it { room.attendee_key.should == "321" }
    end
  end

  context "using the api" do
    before { mock_server_and_api }
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }

    describe "#fetch_is_running?" do

      it { should respond_to(:fetch_is_running?) }

      context "fetches 'running' when not running" do
        before {
          mocked_api.should_receive(:is_meeting_running?).with(room.meetingid).and_return(false)
          room.should_receive(:require_server)
          room.server = mocked_server
        }
        before(:each) { @response = room.fetch_is_running? }
        it { room.running.should be_falsey }
        it { room.is_running?.should be_falsey }
        it { @response.should be_falsey }
      end

      context "fetches 'running' when running" do
        before {
          mocked_api.should_receive(:is_meeting_running?).with(room.meetingid).and_return(true)
          room.should_receive(:require_server)
          room.server = mocked_server
        }
        before(:each) { @response = room.fetch_is_running? }
        it { room.running.should be_truthy }
        it { room.is_running?.should be_truthy }
        it { @response.should be_truthy }
      end

    end

    describe "#fetch_meeting_info" do
      let(:user) { FactoryGirl.build(:user) }

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
      let(:metadata) {
        m = {}
        m[BigbluebuttonRails.metadata_user_id] = user.id
        m[BigbluebuttonRails.metadata_user_name] = user.name
        m
      }
      let(:hash_info2) {
        { :returncode=>true, :meetingID=>"test_id", :attendeePW=>"1234", :moderatorPW=>"4321",
          :running=>true, :hasBeenForciblyEnded=>false, :startTime=>DateTime.parse("Wed Apr 06 17:09:57 UTC 2011"),
          :endTime=>nil, :participantCount=>4, :moderatorCount=>2, :metadata=>metadata,
          :attendees=>users, :messageKey=>{ }, :message=>{ }
        }
      }

      it { should respond_to(:fetch_meeting_info) }

      context "fetches meeting info when the meeting is not running" do
        before {
          mocked_api.should_receive(:get_meeting_info).
            with(room.meetingid, room.moderator_api_password).and_return(hash_info)
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
            with(room.meetingid, room.moderator_api_password).and_return(hash_info2)
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

      context "calls #update_current_meeting after the information is fetched" do
        before {
          mocked_api.should_receive(:get_meeting_info).
            with(room.meetingid, room.moderator_api_password).and_return(hash_info2)
          room.should_receive(:require_server)
          room.server = mocked_server

          # here's the validation
          room.should_receive(:update_current_meeting).with(metadata)
        }
        it { room.fetch_meeting_info }
      end
    end

    describe "#send_end" do
      it { should respond_to(:send_end) }

      context "calls end_meeting" do
        before {
          mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_api_password)
          room.should_receive(:require_server)
          room.server = mocked_server
        }
        it { room.send_end }
      end

      context "schedules a BigbluebuttonMeetingUpdater" do
        before { mocked_api.should_receive(:end_meeting) }
        before(:each) {
          expect {
            room.send_end
          }.to change{ Resque.info[:pending] }.by(1)
        }
        subject { Resque.peek(:bigbluebutton_rails) }
        it("should have a job schedule") { subject.should_not be_nil }
        it("the job should be the right one") { subject['class'].should eq('BigbluebuttonMeetingUpdater') }
        it("the job should have the correct parameters") { subject['args'].should eq([room.id, 15]) }
      end
    end

    describe "#send_create" do
      let(:time) { 1409531761442 }
      let(:new_moderator_api_password) { Forgery(:basic).password }
      let(:new_attendee_api_password) { Forgery(:basic).password }
      let(:hash_create) {
        {
          :returncode => "SUCCESS", :meetingID => "test_id",
          :attendeePW => new_attendee_api_password, :moderatorPW => new_moderator_api_password,
          :createTime => time,
          :hasBeenForciblyEnded => "false", :messageKey => {}, :message => {}
        }
      }
      let(:expected_params) { get_create_params(room) }
      before {
        room.update_attributes(:welcome_msg => "Anything")
        FactoryGirl.create(:bigbluebutton_room_metadata, :owner => room)
        FactoryGirl.create(:bigbluebutton_room_metadata, :owner => room)
        mocked_api.stub(:"request_headers=")
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

      context "sets the room's create_time" do
        before do
          mocked_api.should_receive(:create_meeting)
            .with(room.name, room.meetingid, get_create_params(room))
            .and_return(hash_create)
          room.stub(:select_server).and_return(mocked_server)
          room.server = mocked_server
          room.send_create
        end

        it { expect(room.create_time).to eq(time) }
      end

      context "sends create_meeting" do

        context "for a stored room" do
          before do
            mocked_api.should_receive(:create_meeting)
              .with(room.name, room.meetingid, expected_params)
              .and_return(hash_create)
            room.stub(:select_server).and_return(mocked_server)

            room.server = mocked_server
            room.send_create
          end
          it { room.attendee_api_password.should be(new_attendee_api_password) }
          it { room.moderator_api_password.should be(new_moderator_api_password) }
          it { room.changed?.should be_falsey }
        end

        context "for a new record" do
          let(:new_room) { FactoryGirl.build(:bigbluebutton_room) }
          before do
            params  = get_create_params(new_room)
            mocked_api.should_receive(:create_meeting)
              .with(new_room.name, new_room.meetingid, params)
              .and_return(hash_create)
            new_room.stub(:select_server).and_return(mocked_server)
            new_room.server = mocked_server
            new_room.send_create
          end
          it { new_room.attendee_api_password.should be(new_attendee_api_password) }
          it { new_room.moderator_api_password.should be(new_moderator_api_password) }
          it("and do not save the record") { new_room.new_record?.should be_truthy }
        end

        context "passing the user" do
          let(:user) { FactoryGirl.build(:user) }
          before do
            params = get_create_params(room, user)
            mocked_api.should_receive(:create_meeting)
              .with(room.name, room.meetingid, params)
              .and_return(hash_create)
            room.stub(:select_server).and_return(mocked_server)
            room.server = mocked_server
            room.send_create(user)
          end
          it { room.attendee_api_password.should be(new_attendee_api_password) }
          it { room.moderator_api_password.should be(new_moderator_api_password) }
          it { room.changed?.should be_falsey }
        end

        context "passing additional options" do
          let(:user) { FactoryGirl.build(:user) }
          let(:user_opts) { { :record_meeting => false, :other => true } }
          before do
            params = get_create_params(room, user).merge(user_opts)
            mocked_api.should_receive(:create_meeting)
              .with(room.name, room.meetingid, params)
              .and_return(hash_create)
            room.stub(:select_server).and_return(mocked_server)
            room.server = mocked_server
            room.send_create(user, user_opts)
          end
          it { room.attendee_api_password.should be(new_attendee_api_password) }
          it { room.moderator_api_password.should be(new_moderator_api_password) }
          it { room.changed?.should be_falsey }
        end
      end

      context "generating a meeting id" do
        let(:new_id) { "new id" }

        ['', nil].each do |value|
          it "generates a new one if it's empty or nil" do
            room.meetingid = value
            room.stub(:select_server).and_return(mocked_server)
            room.server = mocked_server
            room.should_receive(:unique_meetingid).and_return(new_id)
            mocked_api.should_receive(:create_meeting)
              .with(room.name, new_id, anything)
            room.send_create
          end
        end

        it "doesn't generate a new meetingid if already set" do
          old_id = "old id"
          room.meetingid = old_id
          room.stub(:select_server).and_return(mocked_server)
          room.server = mocked_server
          room.should_not_receive(:unique_meetingid)
          mocked_api.should_receive(:create_meeting)
            .with(room.name, old_id, anything)
          room.send_create
        end
      end

      context "generating a moderator password" do
        let(:new_pass) { "new pass" }

        ['', nil].each do |value|
          it "generates a new one if it's empty or nil" do
            room.moderator_api_password = value
            room.stub(:select_server).and_return(mocked_server)
            room.server = mocked_server
            room.should_receive(:internal_password).and_return(new_pass)
            mocked_api.should_receive(:create_meeting)
              .with(room.name, anything, hash_including(moderatorPW: new_pass))
            room.send_create
          end
        end

        it "doesn't generate a new moderator password if already set" do
          old_pass = "old pass"
          room.moderator_api_password = old_pass
          room.stub(:select_server).and_return(mocked_server)
          room.server = mocked_server
          room.should_not_receive(:internal_password)
          mocked_api.should_receive(:create_meeting)
            .with(room.name, anything, hash_including(moderatorPW: old_pass))
          room.send_create
        end
      end

      context "generating a attendee password" do
        let(:new_pass) { "new pass" }

        ['', nil].each do |value|
          it "generates a new one if it's empty or nil" do
            room.attendee_api_password = value
            room.stub(:select_server).and_return(mocked_server)
            room.server = mocked_server
            room.should_receive(:internal_password).and_return(new_pass)
            mocked_api.should_receive(:create_meeting)
              .with(room.name, anything, hash_including(attendeePW: new_pass))
            room.send_create
          end
        end

        it "doesn't generate a new attendee password if already set" do
          old_pass = "old pass"
          room.attendee_api_password = old_pass
          room.stub(:select_server).and_return(mocked_server)
          room.server = mocked_server
          room.should_not_receive(:internal_password)
          mocked_api.should_receive(:create_meeting)
            .with(room.name, anything, hash_including(attendeePW: old_pass))
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
            room.should_receive(:internal_create_meeting)
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
            new_room.should_receive(:internal_create_meeting).and_return(nil)
            new_room.should_not_receive(:save)
            new_room.server = mocked_server
            new_room.send_create
          end
          it { new_room.new_record?.should be_truthy }
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
      let(:join_options) { { :any_key => 'any value' } }

      it { should respond_to(:join_url) }

      context "with moderator role" do
        let(:expected) { 'expected-url' }
        before {
          room.should_receive(:require_server)
          mocked_api.should_receive(:join_meeting_url)
            .with(room.meetingid, username, room.moderator_api_password, join_options)
            .and_return(expected)
          room.server = mocked_server
        }
        subject { room.join_url(username, :moderator, nil, join_options) }
        it("returns the correct url") { subject.should eq(expected) }
      end

      context "with attendee role" do
        let(:expected) { 'expected-url' }
        before {
          room.should_receive(:require_server)
          mocked_api.should_receive(:join_meeting_url)
            .with(room.meetingid, username, room.attendee_api_password, join_options)
            .and_return(expected)
          room.server = mocked_server
        }
        subject { room.join_url(username, :attendee, nil, join_options) }
        it("returns the correct url") { subject.should eq(expected) }
      end

      context "without a role" do
        context "passing the moderator key" do
          let(:expected) { 'expected-url' }
          before {
            room.should_receive(:require_server)
            mocked_api.should_receive(:join_meeting_url)
              .with(room.meetingid, username, room.moderator_api_password, join_options)
              .and_return(expected)
            room.server = mocked_server
          }
          subject { room.join_url(username, nil, room.moderator_key, join_options) }
          it("returns the correct url") { subject.should eq(expected) }
        end

        context "passing the attendee key" do
          let(:expected) { 'expected-url' }
          before {
            room.should_receive(:require_server)
            mocked_api.should_receive(:join_meeting_url)
              .with(room.meetingid, username, room.attendee_api_password, join_options)
              .and_return(expected)
            room.server = mocked_server
          }
          subject { room.join_url(username, nil, room.attendee_key, join_options) }
          it("returns the correct url") { subject.should eq(expected) }
        end

        context "passing an unmatching key" do
          let(:expected) { 'expected-url' }
          before {
            room.should_receive(:require_server)
            mocked_api.should_receive(:join_meeting_url)
              .with(room.meetingid, username, nil, join_options)
              .and_return(expected)
            room.server = mocked_server
          }
          subject { room.join_url(username, nil, "wrong key", join_options) }
          it("returns the correct url") { subject.should eq(expected) }
        end
      end

      context "strips the url before returning it" do
        before {
          room.should_receive(:require_server)
          mocked_api.should_receive(:join_meeting_url)
            .and_return(" my.url/with/spaces \t ")
          room.server = mocked_server
        }
        subject { room.join_url(username, :moderator) }
        it("returns the url stripped") { subject.should eq('my.url/with/spaces') }
      end
    end

    describe "#fetch_new_token" do
      let(:config_xml) {
        '<config>
           <localeversion suppressWarning="false">0.8</localeversion>
           <version>0.8</version>
           <layout showLogButton="false" showVideoLayout="false" showResetLayout="false" defaultLayout="Webinar" showToolbar="true" showFooter="true" showMeetingName="true" showHelpButton="true" showLogoutWindow="true" showLayoutTools="true" showNetworkMonitor="true" confirmLogout="true"/>
           <modules>
             <module name="LayoutModule" url="http://server.test/client/LayoutModule.swf?v=15" uri="rtmp://server.test/bigbluebutton" layoutConfig="http://server.test/client/conf/layout.xml" enableEdit="true"/>
           </modules>
         </config>'
      }

      context "if room options is modified" do
        before {
          room.room_options.should_receive(:is_modified?)
            .and_return(true)
          mocked_api.should_receive(:get_default_config_xml).and_return(config_xml)
        }

        context "and the xml generated is not equal the default one" do
          before {
            room.room_options.should_receive(:set_on_config_xml)
              .with(config_xml).and_return('fake-config-xml')
            mocked_api.should_receive(:set_config_xml)
              .with(room.meetingid, 'fake-config-xml')
              .and_return('fake-token')
          }
          it("returns the token generated") { room.fetch_new_token.should eql('fake-token') }
        end

        context "and the xml generated is equal the default one" do
          before {
            room.room_options.should_receive(:set_on_config_xml)
              .with(config_xml).and_return(false)
            mocked_api.should_not_receive(:set_config_xml)
          }
          it("returns nil") { room.fetch_new_token.should be_nil }
        end
      end

      context "if room options is not modified" do
        before {
          room.room_options.should_receive(:is_modified?)
            .and_return(false)
          mocked_api.should_not_receive(:get_default_config_xml)
          mocked_api.should_not_receive(:set_config_xml)
        }
        it("returns nil") { room.fetch_new_token.should be_nil }
      end
    end

  end

  context "validates keys" do
    context "for private rooms" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :private => true) }
      it { room.should_not allow_value('').for(:moderator_key) }
      it { room.should_not allow_value('').for(:attendee_key) }
    end

    context "for public rooms" do
      let(:room) { FactoryGirl.create(:bigbluebutton_room, :private => false) }
      it { room.should allow_value('').for(:moderator_key) }
      it { room.should allow_value('').for(:attendee_key) }
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
      subject { room.create_meeting(user) }
      it { should be_falsey }
    end

    context "when the conference is not running" do
      before {
        room.should_receive(:is_running?).and_return(false)
        room.should_receive(:send_create).with(user, {})
      }
      subject { room.create_meeting(user) }
      it { should be_truthy }
    end

    context "when the parameter 'request' is informed" do
      let(:request) { double(ActionDispatch::Request) }
      before {
        request.stub(:protocol).and_return("HTTP://")
        request.stub(:host_with_port).and_return("test.com:80")
        room.should_receive(:add_domain_to_logout_url).with("HTTP://", "test.com:80")
        room.should_receive(:is_running?).and_return(false)
        room.should_receive(:send_create)
      }
      subject { room.create_meeting(user, request) }
      it { should be_truthy }
    end

    # context "when the parameter 'request' is informed" do
    #   let(:request) { double(ActionDispatch::Request) }
    #   before {
    #     request.stub(:protocol).and_return("HTTP://")
    #     request.stub(:host_with_port).and_return("test.com:80")
    #     room.should_receive(:add_domain_to_logout_url).with("HTTP://", "test.com:80")
    #     room.should_receive(:is_running?).and_return(false)
    #     room.should_receive(:send_create)
    #   }
    #   subject { room.create_meeting(user.name, user.id, request) }
    #   it { should be_truthy }
    # end
  end

  describe "#full_logout_url" do
    subject { BigbluebuttonRoom.new }
    it { should respond_to(:full_logout_url) }
    it { should respond_to(:"full_logout_url=") }
  end

  describe "#require_server" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }
    it { room.respond_to?(:require_server, true).should be(true) }

    context "throws exception when the room has no server associated" do
      before { room.server = nil }
      it {
        expect {
          room.send(:require_server)
        }.to raise_error(BigbluebuttonRails::ServerRequired)
      }
    end

    context "does nothing if the room has a server associated" do
      before { room.server = FactoryGirl.create(:bigbluebutton_server) }
      it {
        expect {
          room.send(:require_server)
        }.not_to raise_error()
      }
    end
  end

  describe "#select_server" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room, :server => nil) }
    it { room.respond_to?(:select_server, true).should be(true) }

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

  describe "#get_current_meeting" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room, :server => nil) }

    context "if there's no start_time set in the room" do
      before { room.start_time = nil }
      it { room.get_current_meeting.should be_nil }
    end

    context "if the room has a start_time set" do
      before {
        @m1 = FactoryGirl.create(:bigbluebutton_meeting, :room => room, :start_time => Time.now.utc - 2.minutes)
        @m2 = FactoryGirl.create(:bigbluebutton_meeting, :room => room, :start_time => Time.now.utc)
        room.start_time = @m1.start_time
      }
      it("returns the correct BigbluebuttonMeeting") { room.get_current_meeting.should eql(@m1) }
    end
  end

  describe "#update_current_meeting" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }

    context "if @start_time is not set in the room" do
      before { room.start_time = nil }
      subject { room.update_current_meeting }
      it("doesn't create a meeting") {
        BigbluebuttonMeeting.find_by_room_id(room.id).should be_nil
      }
    end

    context "if @start_time is set" do
      let(:user) { FactoryGirl.build(:user) }
      let(:metadata) {
        m = {}
        m[BigbluebuttonRails.metadata_user_id] = user.id
        m[BigbluebuttonRails.metadata_user_name] = user.name
        m
      }
      before {
        room.start_time = Time.now.utc
        room.running = !room.running # to change its default value
        room.record_meeting = !room.record_meeting   # to change its default value
      }

      context "if there's no meeting associated yet creates one" do
        context "and no metadata was passed" do
          before { room.running = true }
          before(:each) {
            expect {
              room.update_current_meeting
            }.to change{ BigbluebuttonMeeting.count }.by(1)
          }
          subject { BigbluebuttonMeeting.find_by_room_id(room.id) }
          it("sets server") { subject.server.should eq(room.server) }
          it("sets room") { subject.room.should eq(room) }
          it("sets meetingid") { subject.meetingid.should eq(room.meetingid) }
          it("sets name") { subject.name.should eq(room.name) }
          it("sets recorded") { subject.recorded.should eq(room.record_meeting) }
          it("sets running") { subject.running.should eq(room.running) }
          it("sets start_time") { subject.start_time.utc.to_i.should eq(room.start_time.utc.to_i) }
          it("doesn't set creator_id") { subject.creator_id.should be_nil }
          it("doesn't set creator_name") { subject.creator_name.should be_nil }
        end

        context "and metadata was passed" do
          before { room.running = true }
          before(:each) {
            expect {
              room.update_current_meeting(metadata)
            }.to change{ BigbluebuttonMeeting.count }.by(1)
          }
          subject { BigbluebuttonMeeting.find_by_room_id(room.id) }
          it("sets creator_id") { subject.creator_id.should eq(user.id) }
          it("sets creator_name") { subject.creator_name.should eq(user.name) }
        end
      end

      context "if there's no meeting associated yet but the meeting is not running" do
        before { room.running = false }
        before(:each) {
          expect {
            room.update_current_meeting
          }.not_to change{ BigbluebuttonMeeting.count }
        }
        subject { BigbluebuttonMeeting.find_by_room_id(room.id) }
        it("shouldn't create a meeting") { subject.should be_nil }
      end

      context "if there's already a meeting associated updates it" do
        context "and no metadata was passed" do
          before {
            FactoryGirl.create(:bigbluebutton_meeting, :room => room, :start_time => room.start_time)
          }
          before(:each) {
            expect {
              room.update_current_meeting
            }.not_to change{ BigbluebuttonMeeting.count }
          }
          subject { BigbluebuttonMeeting.find_by_room_id(room.id) }
          it("sets server") { subject.server.should eq(room.server) }
          it("sets room") { subject.room.should eq(room) }
          it("sets meetingid") { subject.meetingid.should eq(room.meetingid) }
          it("sets name") { subject.name.should eq(room.name) }
          it("sets recorded") { subject.recorded.should eq(room.record_meeting) }
          it("sets running") { subject.running.should eq(room.running) }
          it("sets start_time") { subject.start_time.utc.to_i.should eq(room.start_time.utc.to_i) }
          it("doesn't set creator_id") { subject.creator_id.should be_nil }
          it("doesn't set creator_name") { subject.creator_name.should be_nil }
        end

        context "and metadata was passed" do
          before {
            FactoryGirl.create(:bigbluebutton_meeting, :room => room, :start_time => room.start_time)
          }
          before(:each) {
            expect {
              room.update_current_meeting(metadata)
            }.not_to change{ BigbluebuttonMeeting.count }
          }
          subject { BigbluebuttonMeeting.find_by_room_id(room.id) }
          it("sets creator_id") { subject.creator_id.should eq(user.id) }
          it("sets creator_name") { subject.creator_name.should eq(user.name) }
        end
      end
    end
  end

  describe "#finish_meetings" do
    let!(:room) { FactoryGirl.create(:bigbluebutton_room) }

    context "finishes all meetings related to this room that are still running" do
      let!(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting, room: room, running: true) }
      let!(:meeting2) { FactoryGirl.create(:bigbluebutton_meeting, room: room, running: true) }
      before(:each) { room.finish_meetings }
      it { meeting1.reload.running.should be(false) }
      it { meeting2.reload.running.should be(false) }
    end

    context "works if the room has no meetings" do
      it { room.finish_meetings }
    end

    context "works if the room has no meetings running" do
      let!(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting, room: room, running: false) }
      let!(:meeting2) { FactoryGirl.create(:bigbluebutton_meeting, room: room, running: false) }
      it { room.finish_meetings }
      it { meeting1.reload.running.should be(false) }
      it { meeting2.reload.running.should be(false) }
    end
  end

  describe "#internal_create_meeting" do
    it "creates the correct hash of parameters"
    it "adds metadata with the user's id"
    it "adds metadata with the user's name"
    it "sets the request headers"
    it "calls api.create_meeting"
    it "accepts additional user options to override the options in the database"

    context "schedules a BigbluebuttonMeetingUpdater" do
      before { mock_server_and_api }
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }

      before {
        mocked_api.stub(:create_meeting)
        mocked_api.stub(:"request_headers=")
        room.server = mocked_server
      }
      before(:each) {
        expect {
          room.send(:internal_create_meeting)
        }.to change{ Resque.info[:pending] }.by(1)
      }
      subject { Resque.peek(:bigbluebutton_rails) }
      it("should have a job schedule") { subject.should_not be_nil }
      it("the job should be the right one") { subject['class'].should eq('BigbluebuttonMeetingUpdater') }
      it("the job should have the correct parameters") { subject['args'].should eq([room.id]) }
    end
  end

end

def get_create_params(room, user=nil)
  params = {
    :record => room.record_meeting,
    :duration => room.duration,
    :moderatorPW => room.moderator_api_password,
    :attendeePW => room.attendee_api_password,
    :welcome  => room.welcome_msg,
    :dialNumber => room.dial_number,
    :logoutURL => room.logout_url,
    :maxParticipants => room.max_participants,
    :voiceBridge => room.voice_bridge,
  }
  room.metadata.each { |meta| params["meta_#{meta.name}"] = meta.content }
  unless user.nil?
    userid = user.send(:id)
    username = user.send(:name)
    params.merge!({ "meta_bbbrails-user-id" => userid })
    params.merge!({ "meta_bbbrails-user-name" => username })
  end
  params
end
