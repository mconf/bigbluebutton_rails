# coding: utf-8
require 'spec_helper'
require 'support/models/bigbluebutton_room_support'

RSpec.configure do |c|
  c.include BigbluebuttonRoomSupport
end

shared_examples_for :RoomWithNoMeetings do |args|
  room = args[:room]
  it { room.meetings.count.should == 0 }
end
shared_examples_for :RoomWithMeetings do |args|
  room = args[:room]
  meetings_count = args[:meetings_count]
  last_meeting_ended = args[:last_meeting_ended]
  last_meeting_create_time = args[:last_meeting_create_time]
  it { room.meetings.count.should > 0 }
  it { room.meetings.count.should == meetings_count }
  unless last_meeting_create_time.nil?
    it { room.meetings.last.create_time == create_time }
  end
  unless last_meeting_ended.nil?
    it { room.get_current_meeting.should == (last_meeting_ended ? nil : room.meetings.last) }
    it { room.meetings.last.running == !last_meeting_ended }
    it { room.meetings.last.ended == last_meeting_ended }
  end
end

describe BigbluebuttonRoom do
  it "loaded correctly" do
    BigbluebuttonRoom.new.should be_a_kind_of(ActiveRecord::Base)
  end



  before { FactoryGirl.create(:bigbluebutton_room) }
  it { should belong_to(:owner) }
  it { should_not validate_presence_of(:owner_id) }
  it { should_not validate_presence_of(:owner_type) }

  it { should have_many(:recordings).dependent(:nullify) }

  it { should have_many(:metadata).dependent(:destroy) }

  it { should validate_presence_of(:meetingid) }
  it { should validate_uniqueness_of(:meetingid) }
  it { should ensure_length_of(:meetingid).is_at_least(1).is_at_most(100) }

  it { should validate_presence_of(:name) }
  it { should ensure_length_of(:name).is_at_least(1).is_at_most(250) }

  it { should validate_presence_of(:slug) }
  it { should validate_uniqueness_of(:slug) }
  it { should ensure_length_of(:slug).is_at_least(1) }

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
  [:participant_count, :moderator_count, :current_attendees,
   :has_been_forcibly_ended, :end_time, :external,
   :request_headers, :record_meeting, :duration].each do |attr|
    it { should respond_to(attr) }
    it { should respond_to("#{attr}=") }
  end

  context ".to_param" do
    it { should respond_to(:to_param) }
    it {
      r = FactoryGirl.create(:bigbluebutton_room)
      r.to_param.should be(r.slug)
    }
  end

  it { should respond_to(:is_running?) }

  describe ".order_by_activity" do
    let!(:room1) { FactoryGirl.create(:bigbluebutton_room) }
    let!(:room2) { FactoryGirl.create(:bigbluebutton_room) }
    let!(:room3) { FactoryGirl.create(:bigbluebutton_room) }
    let!(:room4) { FactoryGirl.create(:bigbluebutton_room) }
    let!(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting, create_time: Time.now - 2.hours, room: room1) }
    let!(:meeting2) { FactoryGirl.create(:bigbluebutton_meeting, create_time: Time.now, room: room2) }
    let!(:meeting3) { FactoryGirl.create(:bigbluebutton_meeting, create_time: Time.now - 1.hour, room: room3) }
    let!(:meeting4) { FactoryGirl.create(:bigbluebutton_meeting, create_time: Time.now - 3.hour, room: room4) }

    context "ASC" do
      subject { BigbluebuttonRoom.order_by_activity }
      it { subject[0].should eql(room4) }
      it { subject[1].should eql(room1) }
      it { subject[2].should eql(room3) }
      it { subject[3].should eql(room2) }
    end

    context "DESC" do
      subject { BigbluebuttonRoom.order_by_activity('DESC') }
      it { subject[0].should eql(room2) }
      it { subject[1].should eql(room3) }
      it { subject[2].should eql(room1) }
      it { subject[3].should eql(room4) }
    end
  end

  describe ".search_by_terms" do
    let!(:rooms) {
      [
        FactoryGirl.create(:bigbluebutton_room, name: "La Lo", slug: "lalo-1"),
        FactoryGirl.create(:bigbluebutton_room, name: "La Le", slug: "lale-2"),
        FactoryGirl.create(:bigbluebutton_room, name: "Li Lo", slug: "lilo")
      ]
    }
    let(:subject) { BigbluebuttonRoom.search_by_terms(terms) }

    context '1 term finds something' do
      let(:terms) { ['la'] }
      it { subject.count.should be(2) }
      it { subject.should include(rooms[0], rooms[1]) }
    end

    context 'composite term finds something' do
      let(:terms) { ['la lo'] }
      it { subject.count.should be(1) }
      it { subject.should include(rooms[0]) }
    end

    context '2 terms find something' do
      let(:terms) { ['la', 'lo'] }
      it { subject.count.should be(3) }
      it { subject.should include(rooms[0], rooms[1], rooms[2]) }
    end

    context '1 term finds nothing 1 term finds something' do
      let(:terms) { ['la', 'notfound'] }
      it { subject.count.should be(2) }
      it { subject.should include(rooms[0], rooms[1]) }
    end

    context '1 term finds nothing' do
      let(:terms) { ['notfound'] }
      it { subject.count.should eq(0) }
    end

    context 'multiple terms find nothing' do
      let(:terms) { ['nope', 'not', 'found'] }
      it { subject.count.should eq(0) }
    end

    context "searches by both name and params" do
      let(:terms) { ['abcdef'] }
      before {
        rooms[1].update_attributes(name: 'abcdef')
        rooms[2].update_attributes(slug: 'abcdef')
      }
      it { subject.count.should be(2) }
      it { subject.should include(rooms[1], rooms[2]) }
    end

    context "returns a Relation object" do
      let(:terms) { [''] }
      it { subject.should be_kind_of(ActiveRecord::Relation) }
    end

    context "accepts a string as parameter" do
      let(:terms) { 'la' }
      it { subject.count.should be(2) }
      it { subject.should include(rooms[0], rooms[1]) }
    end

    context "is chainable" do
      subject { BigbluebuttonRoom.search_by_terms('l').where(id: rooms[0].id) }
      it { subject.count.should be(1) }
      it { subject.should include(rooms[0]) }
    end
  end

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

    context "when guest support is true" do
      before { BigbluebuttonRails.configuration.guest_support = true }
      it { room.user_role({ :key => room.attendee_key }).should == :guest }
    end
  end

  describe "#instance_variables_compare" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }
    let(:room2) { BigbluebuttonRoom.last }
    it { should respond_to(:instance_variables_compare) }
    it { room.instance_variables_compare(room2).should be_empty }
    it "compares instance variables" do
      room2.end_time = !room.end_time
      room.instance_variables_compare(room2).should_not be_empty
      room.instance_variables_compare(room2).should include(:@end_time)
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
      room2.end_time = !room.end_time
      room.attr_equal?(room2).should be(false)
    end
    it "differentiates attributes" do
      room2.private = !room.private
      room.attr_equal?(room2).should be(false)
    end
    it "differentiates objects" do
      room2 = room.dup
      room.attr_equal?(room2).should be(false)
    end
  end

  context "initializes" do
    let(:room) { BigbluebuttonRoom.new }

    it "fetched attributes before they are fetched" do
      room.participant_count.should be(0)
      room.moderator_count.should be(0)
      room.has_been_forcibly_ended.should be(false)
      room.meetings.count.should be(0)
      room.get_current_meeting.should be_nil
      room.end_time.should be_nil
      room.current_attendees.should eql([])
      room.request_headers.should == {}
    end

    context "meetingid" do
      it { room.meetingid.should_not be_nil }
      it {
        b = BigbluebuttonRoom.new(:meetingid => "user defined")
        b.meetingid.should == "user defined"
      }
    end
  end

  context "#slug format" do
    let(:msg) { I18n.t('bigbluebutton_rails.rooms.errors.slug_format') }
    it { should_not allow_value("123 321").for(:slug).with_message(msg) }
    it { should_not allow_value("").for(:slug).with_message(msg) }
    it { should_not allow_value("ab@c").for(:slug).with_message(msg) }
    it { should_not allow_value("ab#c").for(:slug).with_message(msg) }
    it { should_not allow_value("ab$c").for(:slug).with_message(msg) }
    it { should_not allow_value("ab%c").for(:slug).with_message(msg) }
    it { should_not allow_value("ábcd").for(:slug).with_message(msg) }
    it { should_not allow_value("-abc").for(:slug).with_message(msg) }
    it { should_not allow_value("abc-").for(:slug).with_message(msg) }
    it { should_not allow_value("-").for(:slug).with_message(msg) }
    it { should allow_value("_abc").for(:slug).with_message(msg) }
    it { should allow_value("abc_").for(:slug).with_message(msg) }
    it { should allow_value("abc").for(:slug).with_message(msg) }
    it { should allow_value("123").for(:slug).with_message(msg) }
    it { should allow_value("1").for(:slug).with_message(msg) }
    it { should allow_value("a").for(:slug).with_message(msg) }
    it { should allow_value("_").for(:slug).with_message(msg) }
    it { should allow_value("abc-123_d5").for(:slug).with_message(msg) }
  end

  context "sets slug as the downcased parameterized name if slug is" do
    after :each do
      @room.save.should be_truthy
      @room.slug.should == @room.name.downcase.parameterize
    end
    it "nil" do
      @room = FactoryGirl.build(:bigbluebutton_room, slug: nil, name: "-My Name@ _Is Odd_-")
    end
    it "empty" do
      @room = FactoryGirl.build(:bigbluebutton_room, slug: "", name: "-My Name@ _Is Odd_-")
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
          room.should_receive(:select_server).and_return(mocked_server)
        }
        before(:each) { @response = room.fetch_is_running? }
        it { @response.should be(false) }
      end

      context "fetches 'running' when running" do
        before {
          mocked_api.should_receive(:is_meeting_running?).with(room.meetingid).and_return(true)
          room.should_receive(:select_server).and_return(mocked_server)
        }
        before(:each) { @response = room.fetch_is_running? }
        it { @response.should be_truthy }
      end

    end

    describe "#fetch_meeting_info" do
      let(:user) { FactoryGirl.build(:user) }

      # these hashes should be exactly as returned by bigbluebutton-api-ruby to be sure we are testing it right
      let(:hash_info) {
        { :returncode=>true, :meetingID=>"test_id", :attendeePW=>"1234", :moderatorPW=>"4321",
          :running=>false, :hasBeenForciblyEnded=>false, :startTime=>nil, :createTime=>Time.now.to_i, :endTime=>nil,
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
        m[BigbluebuttonRails.configuration.metadata_user_id] = user.id
        m[BigbluebuttonRails.configuration.metadata_user_name] = user.name
        m
      }
      let(:hash_info2) {
        { :returncode=>true, :meetingID=>"test_id", :attendeePW=>"1234", :moderatorPW=>"4321",
          :running=>true, :hasBeenForciblyEnded=>false, :startTime=>DateTime.parse("Wed Apr 06 17:09:57 UTC 2011"),
          :endTime=>nil, :participantCount=>4, :moderatorCount=>2, :metadata=>metadata,
          :createTime=>Time.now.to_i + 123, :attendees=>users, :messageKey=>{ }, :message=>{ }
        }
      }

      it { should respond_to(:fetch_meeting_info) }

      context "fetches meeting info when the meeting is not running" do
        before {
          mocked_api.should_receive(:get_meeting_info).
            with(room.meetingid, room.moderator_api_password).and_return(hash_info)
          room.should_receive(:select_server).and_return(mocked_server)
        }
        before(:each) { room.fetch_meeting_info }

        context "with no meetings" do
          let(:room) { create_room_without_meetings }
          it { room.has_been_forcibly_ended.should == false }
          it { room.participant_count.should == 0 }
          it { room.moderator_count.should == 0 }
          it { room.end_time.should == nil }
          it { room.current_attendees.should == [] }
        end
        context "with meetings" do
          context "with no meeting running" do
            let(:meetings_count) { 3 }
            let(:ended) { true }
            let(:room) do
              create_room_with_meetings(meetings_count: meetings_count,
                                        ended: ended)
            end
            it { room.has_been_forcibly_ended.should == false }
            it { room.participant_count.should == 0 }
            it { room.moderator_count.should == 0 }
            it { room.current_attendees.should == [] }
            it { room.get_current_meeting.should be nil}
          end
          context "with meeting running" do
            let(:meetings_count) { 4 }
            let(:ended) { false }
            let(:room) do
              create_room_with_meetings(meetings_count: meetings_count,
                                        ended: ended)
            end
            it { room.get_current_meeting.create_time.should be hash_info[:createTime] }
            it { room.has_been_forcibly_ended.should == false }
            it { room.participant_count.should == 0 }
            it { room.moderator_count.should == 0 }
            it { room.current_attendees.should == [] }
          end
        end
      end

      context "fetches meeting info when the meeting is running" do
        before {
          mocked_api.should_receive(:get_meeting_info).
            with(room.meetingid, room.moderator_api_password).and_return(hash_info2)
          room.should_receive(:select_server).and_return(mocked_server)
        }
        before(:each) { room.fetch_meeting_info }
        it { room.has_been_forcibly_ended.should == false }
        it { room.participant_count.should == 4 }
        it { room.moderator_count.should == 2 }
        it { room.end_time.should == nil }
        it {
          users.each do |att|
            attendee = BigbluebuttonAttendee.new
            attendee.from_hash(att)
            found = room.current_attendees.select{ |a| a.user_name == attendee.user_name }[0]
            found.user_id.should eql(attendee.user_id)
            found.role.should eql(attendee.role)
          end
        }
        context "with no meetings" do
          let(:room) { create_room_without_meetings }
        end
        context "with meetings" do
          let(:meetings_count) { 5 }
          let(:room) do
            create_room_with_meetings(meetings_count: meetings_count,
                                      ended: ended)
          end
          context 'with no meeting running' do
            let(:ended) { true }
            it { room.get_current_meeting.should be_nil }
          end
          context 'with meeting running' do
            let(:ended) { false }
            it { room.get_current_meeting.create_time.should be hash_info2[:createTime] }
          end
        end
      end

      context "calls #update_current_meeting_record after the information is fetched" do
        before {
          mocked_api.should_receive(:get_meeting_info).
            with(room.meetingid, room.moderator_api_password).and_return(hash_info2)
          room.should_receive(:select_server).and_return(mocked_server)

          # here's the validation
          room.should_receive(:update_current_meeting_record).with(hash_info2, true)
        }
        it { room.fetch_meeting_info }
      end

      shared_examples_for 'BigbluebuttonException, should not raise exception' do
        context 'without meetings' do
          let(:room) { create_room_without_meetings }
          it {
            room.should_receive(:select_server).and_return(mocked_server)
            expect(mocked_api).to receive(:get_meeting_info) { raise exception }
            expect(room).not_to receive(:update_current_meeting_record)
            expect(room).to receive(:finish_meetings).and_call_original
            expect { room.fetch_meeting_info }.not_to raise_exception

            room.get_current_meeting.should be_nil
            room.meetings.count.should == 0
          }
        end
        context 'with meetings' do
          let(:meetings_count) { 6 }
          let(:room) do
            create_room_with_meetings(meetings_count: meetings_count,
                                      ended: ended)
          end
          context 'with no meeting running' do
            let(:ended) { true }
            it {
              room.should_receive(:select_server).and_return(mocked_server)
              expect(mocked_api).to receive(:get_meeting_info) { raise exception }
              expect(room).not_to receive(:update_current_meeting_record)
              expect(room).to receive(:finish_meetings).and_call_original
              expect { room.fetch_meeting_info }.not_to raise_exception

              room.get_current_meeting.should be_nil
              room.meetings.last.ended == true
              room.meetings.last.running == false
            }
          end
          context 'with meeting running' do
            let(:ended) { false }
            it {
              room.should_receive(:select_server).and_return(mocked_server)
              expect(mocked_api).to receive(:get_meeting_info) { raise exception }
              expect(room).not_to receive(:update_current_meeting_record)
              expect(room).to receive(:finish_meetings).and_call_original
              expect { room.fetch_meeting_info }.not_to raise_exception

              room.get_current_meeting.should_not be_nil
              room.meetings.last.ended == false
              room.meetings.last.running == true
            }
          end
        end
      end

      context "if an exception 'notFound' is raised" do
        let(:exception) {
          e = BigBlueButton::BigBlueButtonException.new('Test error')
          e.key = 'notFound'
          e
        }
        it_behaves_like 'BigbluebuttonException, should not raise exception'
      end

      context "if an exception other than 'notFound' is raised" do
        let(:exception) {
          e = BigBlueButton::BigBlueButtonException.new('Test error')
          e.key = 'anythingElse'
          e
        }
        it_behaves_like 'BigbluebuttonException, should not raise exception'
      end

      context "if an exception with a blank key is raised" do
        let(:exception) {
          e = BigBlueButton::BigBlueButtonException.new('Test error')
          e.key = ''
          e
        }
        it_behaves_like 'BigbluebuttonException, should not raise exception'
      end

      context "raises any exception other than a BigBlueButtonException" do
        let!(:exception) { NoMethodError.new('Test error') }
        context 'without meetings' do
          let(:room) { create_room_without_meetings }
          it do
            room.should_receive(:select_server).and_return(mocked_server)
            expect(mocked_api).to receive(:get_meeting_info) { raise exception }
            expect(room).not_to receive(:update_current_meeting_record)
            expect(room).not_to receive(:finish_meetings)
            expect { room.fetch_meeting_info }.to raise_exception
          end
          it { room.get_current_meeting.should be_nil }
        end
        context 'with meetings' do
          let(:meetings_count) { 7 }
          let(:room) do
            create_room_with_meetings(meetings_count: meetings_count,
                                      ended: ended)
          end
          context 'with no meeting running' do
            let(:ended) { true }
            it do
              room.should_receive(:select_server).and_return(mocked_server)
              expect(mocked_api).to receive(:get_meeting_info) { raise exception }
              expect(room).not_to receive(:update_current_meeting_record)
              expect(room).not_to receive(:finish_meetings)
              expect { room.fetch_meeting_info }.to raise_exception
            end
            it { room.get_current_meeting.should be_nil }
          end
          context 'with meeting running' do
            let(:ended) { false }
            it do
              room.should_receive(:select_server).and_return(mocked_server)
              expect(mocked_api).to receive(:get_meeting_info) { raise exception }
              expect(room).not_to receive(:update_current_meeting_record)
              expect(room).not_to receive(:finish_meetings)
              expect { room.fetch_meeting_info }.to raise_exception
            end
            it { room.get_current_meeting.running.should == true }
            it { room.get_current_meeting.ended.should == false }
          end
        end
      end
    end

    describe "#send_end" do
      it { should respond_to(:send_end) }

      context "calls end_meeting" do
        before {
          mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_api_password)
          room.should_receive(:select_server).and_return(mocked_server)
        }
        it { room.send_end }
      end

      context "schedules a BigbluebuttonMeetingUpdaterWorker" do
        before {
          room.should_receive(:select_server).and_return(mocked_server)
          mocked_api.should_receive(:end_meeting)
          expect {
            room.send_end
          }.to change{ Resque.info[:pending] }.by(1)
        }

        subject { Resque.peek(:bigbluebutton_rails) }
        it("should have a job scheduled") { subject.should_not be_nil }
        it("the job should be the right one") { subject['class'].should eq('BigbluebuttonMeetingUpdaterWorker') }
        it("the job should have the correct parameters") { subject['args'].should eq([room.id]) }
      end
    end

    describe "#send_create" do
      let(:time) { 1409531761442 }
      let(:new_moderator_api_password) { Forgery(:basic).password }
      let(:new_attendee_api_password) { Forgery(:basic).password }
      let(:voice_bridge) { SecureRandom.random_number(99999) }
      let(:hash_create) {
        {
          :returncode => "SUCCESS", :meetingID => "test_id",
          :attendeePW => new_attendee_api_password, :moderatorPW => new_moderator_api_password,
          :voiceBridge => voice_bridge, :createTime => time,
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
            .with(room.name, room.meetingid, expected_params)
            .and_return(hash_create)
          room.stub(:select_server).and_return(mocked_server)
          room.send_create
        end

        it { expect(room.get_current_meeting.create_time).to eq(time) }
      end

      context "sends create_meeting" do
        context "for a stored room" do
          before do
            mocked_api.should_receive(:create_meeting)
              .with(room.name, room.meetingid, expected_params)
              .and_return(hash_create)
            room.stub(:select_server).and_return(mocked_server)
            room.send_create
          end
          it { room.attendee_api_password.should be(new_attendee_api_password) }
          it { room.moderator_api_password.should be(new_moderator_api_password) }
          it { room.voice_bridge.should be(voice_bridge) }
          it { room.changed?.should be(false) }
        end

        context "for a new record" do
          let(:new_room) { FactoryGirl.build(:bigbluebutton_room) }
          before do
            params = get_create_params(new_room)
            mocked_api.should_receive(:create_meeting)
              .with(new_room.name, new_room.meetingid, params)
              .and_return(hash_create)
            new_room.stub(:select_server).and_return(mocked_server)
            new_room.send_create
          end
          it { new_room.attendee_api_password.should be(new_attendee_api_password) }
          it { new_room.moderator_api_password.should be(new_moderator_api_password) }
          it { new_room.voice_bridge.should be(voice_bridge) }
          it("doesn't save the record") { new_room.new_record?.should be(true) }
          it("doesn't create a meeting") { BigbluebuttonMeeting.where(room: new_room).should be_empty }
          it("doesn't schedule a meeting updater") {
            Resque.peek(:bigbluebutton_rails).should be_nil
          }
        end

        context "passing the user" do
          let(:user) { FactoryGirl.build(:user) }
          before do
            params = get_create_params(room, user)
            mocked_api.should_receive(:create_meeting)
              .with(room.name, room.meetingid, params)
              .and_return(hash_create)
            room.stub(:select_server).and_return(mocked_server)
            room.send_create(user)
          end
          it { room.attendee_api_password.should be(new_attendee_api_password) }
          it { room.moderator_api_password.should be(new_moderator_api_password) }
          it { room.changed?.should be(false) }
        end

        context "passing metadata from the db" do
          let(:user) { FactoryGirl.build(:user) }
          before do
            mocked_api.should_receive(:create_meeting)
              .with(room.name, room.meetingid, get_create_params(room, user))
              .and_return(hash_create)
            room.stub(:select_server).and_return(mocked_server)
            room.send_create(user)
          end
          it { room.attendee_api_password.should be(new_attendee_api_password) }
          it { room.moderator_api_password.should be(new_moderator_api_password) }
          it { room.changed?.should be(false) }
        end

        context "passing additional user options" do
          let(:user) { FactoryGirl.build(:user) }
          let(:user_opts) { { :record_meeting => false, :other => true } }
          before do
            params = get_create_params(room, user).merge(user_opts)
            BigbluebuttonRails.configuration.should_receive(:get_create_options).and_return(Proc.new{ user_opts })
            mocked_api.should_receive(:create_meeting)
              .with(room.name, room.meetingid, params)
              .and_return(hash_create)
            room.stub(:select_server).and_return(mocked_server)
            room.send_create(user)
          end
          it { room.attendee_api_password.should be(new_attendee_api_password) }
          it { room.moderator_api_password.should be(new_moderator_api_password) }
          it { room.changed?.should be(false) }
        end

        context "when the call to create doesn't return a voice bridge" do
          before do
            room.update_attributes(:voice_bridge => nil)
            hash_create.delete(:voiceBridge)
            mocked_api.should_receive(:create_meeting)
              .with(room.name, room.meetingid, expected_params)
              .and_return(hash_create)
            room.stub(:select_server).and_return(mocked_server)
            room.send_create
          end
          it { room.voice_bridge.should be_nil }
          it { room.changed?.should be(false) }
        end

        context "when it's set to use local voice bridges" do
          before {
            @use_local_voice_bridges = BigbluebuttonRails.configuration.use_local_voice_bridges
            BigbluebuttonRails.configuration.use_local_voice_bridges = true
          }
          after {
            BigbluebuttonRails.configuration.use_local_voice_bridges = @use_local_voice_bridges
          }

          context "sets the voice bridge in the params if there's a voice bridge" do
            let(:voice_bridge) { SecureRandom.random_number(99999) }
            before do
              room.update_attributes(:voice_bridge => voice_bridge)
              create_params = get_create_params(room)
              create_params.merge!({ :voiceBridge => voice_bridge })
              mocked_api.should_receive(:create_meeting)
                .with(room.name, room.meetingid, create_params)
                .and_return(hash_create)
              room.stub(:select_server).and_return(mocked_server)
              room.send_create
            end
            it { room.changed?.should be(false) }
          end

          context "doesn't set the voice bridge if it's blank" do
            let(:voice_bridge) { SecureRandom.random_number(99999) }
            before do
              room.update_attributes(:voice_bridge => "")
              mocked_api.should_receive(:create_meeting)
                .with(room.name, room.meetingid, expected_params)
                .and_return(hash_create)
              room.stub(:select_server).and_return(mocked_server)
              room.send_create
            end
            it { room.changed?.should be(false) }
          end
        end

        context "creates a meeting record" do
          context "set the correct attributes in the record" do
            before do
              mocked_api.should_receive(:create_meeting)
                .with(room.name, room.meetingid, expected_params)
                .and_return(hash_create)
              room.stub(:select_server).and_return(mocked_server)

              expect {
                room.send_create
              }.to change{ BigbluebuttonMeeting.count }.by(1)
            end
            subject { BigbluebuttonMeeting.last }
            it { subject.room.should eql(room) }
            it { subject.server_url.should eql(mocked_server.url) }
            it { subject.server_secret.should eql(mocked_server.secret) }
            it { subject.meetingid.should eql(room.meetingid) }
            it { subject.name.should eql(room.name) }
            it { subject.recorded.should eql(room.record_meeting) }
            it { subject.create_time.should eql(room.get_current_meeting.create_time) }
            it { subject.ended.should eql(false) }
          end

          context "calls create_meeting_record_from_room with the correct arguments" do
            let(:user_opts) { { opt1: 1, opt2: 'two' } }
            let(:response) { { response: 1 } }
            before do
              BigbluebuttonRails.configuration.should_receive(:get_create_options).and_return(Proc.new{ user_opts })
              room.should_receive(:internal_create_meeting) do
                ['my-server', response]
              end
              BigbluebuttonMeeting.should_receive(:create_meeting_record_from_room).with(room, response, 'my-server', 'my-user', user_opts)
            end
            it { room.send_create('my-user') }
          end
        end

        context "enqueues a BigbluebuttonMeetingUpdaterWorker" do
          before do
            mocked_api.should_receive(:create_meeting)
              .with(room.name, room.meetingid, expected_params)
              .and_return(hash_create)
            room.stub(:select_server).and_return(mocked_server)

            expect {
              room.send_create
            }.to change{ Resque.info[:pending] }.by(1)
          end
          subject { Resque.peek(:bigbluebutton_rails) }
          it("should have a job schedule") { subject.should_not be_nil }
          it("the job should be the right one") { subject['class'].should eq('BigbluebuttonMeetingUpdaterWorker') }
          it("the job should have the correct parameters") { subject['args'].should eq([room.id, 10]) }
        end
      end

      context "generating a meeting id" do
        let(:new_id) { "new id" }

        ['', nil].each do |value|
          it "generates a new one if it's empty or nil" do
            room.meetingid = value
            room.stub(:select_server).and_return(mocked_server)
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
          # BigbluebuttonRails.configuration.should_receive(:get_create_options).and_return(Proc.new{ hash })
          mocked_api.should_receive(:create_meeting).
            with(room.name, room.meetingid, hash).and_return(hash_create)
          room.stub(:select_server).and_return(mocked_server)
        end
        it { room.send_create }
      end

      context "selects a server" do
        let(:another_server) { FactoryGirl.create(:bigbluebutton_server) }
        let(:room2) { FactoryGirl.create(:bigbluebutton_room) }
        let(:api) { double(BigBlueButton::BigBlueButtonApi) }

        context "and saves the result" do
          before do
            room2.should_receive(:select_server).with(:create).and_return(another_server)
            another_server.stub(:api).and_return(api)
            api.should_receive(:request_headers=)
            api.should_receive(:create_meeting)
          end
          it { room2.send_create }
        end
      end

      context "sets the request headers in the server api" do
        before do
          mocked_api.should_receive(:create_meeting).with(anything, anything, anything)
          room.stub(:select_server).and_return(mocked_server)
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
          room.should_receive(:select_server).and_return(mocked_server)
          mocked_api.should_receive(:join_meeting_url)
            .with(room.meetingid, username, room.moderator_api_password, join_options)
            .and_return(expected)
        }
        subject { room.join_url(username, :moderator, nil, join_options) }
        it("returns the correct url") { subject.should eq(expected) }
      end

      context "with attendee role" do
        let(:expected) { 'expected-url' }
        before {
          room.should_receive(:select_server).and_return(mocked_server)
          mocked_api.should_receive(:join_meeting_url)
            .with(room.meetingid, username, room.attendee_api_password, join_options)
            .and_return(expected)
        }
        subject { room.join_url(username, :attendee, nil, join_options) }
        it("returns the correct url") { subject.should eq(expected) }
      end

      context "with guest role" do
        let(:expected) { 'expected-url' }

        context "when guest support is disabled" do
          before {
            room.should_receive(:select_server).and_return(mocked_server)
            mocked_api.should_receive(:join_meeting_url)
              .with(room.meetingid, username, room.attendee_api_password, join_options)
              .and_return(expected)
          }
          subject { room.join_url(username, :guest, nil, join_options) }
          it("returns the correct url") { subject.should eq(expected) }
        end

        context "when guest support is enabled" do
          before {
            @guest_support_before = BigbluebuttonRails.configuration.guest_support
            BigbluebuttonRails.configuration.guest_support = true

            room.should_receive(:select_server).and_return(mocked_server)
            params = { guest: true }.merge(join_options)
            mocked_api.should_receive(:join_meeting_url)
              .with(room.meetingid, username, room.attendee_api_password, params)
              .and_return(expected)
          }
          after {
            BigbluebuttonRails.configuration.guest_support = @guest_support_before
          }
          subject { room.join_url(username, :guest, nil, join_options) }
          it("returns the correct url") { subject.should eq(expected) }
        end
      end

      context "without a role" do
        context "passing the moderator key" do
          let(:expected) { 'expected-url' }
          before {
            room.should_receive(:select_server).and_return(mocked_server)
            mocked_api.should_receive(:join_meeting_url)
              .with(room.meetingid, username, room.moderator_api_password, join_options)
              .and_return(expected)
          }
          subject { room.join_url(username, nil, room.moderator_key, join_options) }
          it("returns the correct url") { subject.should eq(expected) }
        end

        context "passing the attendee key" do
          let(:expected) { 'expected-url' }
          before {
            room.should_receive(:select_server).and_return(mocked_server)
            mocked_api.should_receive(:join_meeting_url)
              .with(room.meetingid, username, room.attendee_api_password, join_options)
              .and_return(expected)
          }
          subject { room.join_url(username, nil, room.attendee_key, join_options) }
          it("returns the correct url") { subject.should eq(expected) }
        end

        context "passing an unmatching key" do
          let(:expected) { 'expected-url' }
          before {
            room.should_receive(:select_server).and_return(mocked_server)
            mocked_api.should_receive(:join_meeting_url)
              .with(room.meetingid, username, nil, join_options)
              .and_return(expected)
          }
          subject { room.join_url(username, nil, "wrong key", join_options) }
          it("returns the correct url") { subject.should eq(expected) }
        end
      end

      context "strips the url before returning it" do
        before {
          room.should_receive(:select_server).and_return(mocked_server)
          mocked_api.should_receive(:join_meeting_url)
            .and_return(" my.url/with/spaces \t ")
        }
        subject { room.join_url(username, :moderator) }
        it("returns the url stripped") { subject.should eq('my.url/with/spaces') }
      end
    end

    describe "#parameterized_join_url" do
      let(:username) { Forgery(:name).full_name }
      let(:role) { :attendee }
      let(:id) { 'fake-user-id' }

      context "sets a user id" do
        context "when it exists" do
          before {
            room.should_receive(:join_url).with(username, role, nil, { userID: 'fake-user-id' })
          }
          it { room.parameterized_join_url(username, role, 'fake-user-id') }
        end

        context "when it doesn't exist" do
          before {
            room.should_receive(:join_url).with(username, role, nil, { })
          }
          it { room.parameterized_join_url(username, role, nil) }
        end
      end

      context "uses the options in the parameters" do
        context "when the are set" do
          let(:options) { { option1: 'value1' } }
          before {
            room.should_receive(:join_url).with(username, role, nil, options)
          }
          it { room.parameterized_join_url(username, role, nil, options) }
        end

        context "overrides the options set internally by the method" do
          let(:options) { { option1: 'value1', createTime: 123, userID: 'opts-userid' } }
          before {
            room.should_receive(:join_url).with(username, role, nil, options)
          }
          it { room.parameterized_join_url(username, role, 'opts-userid', options) }
        end
      end

      context "uses the options passed by the application" do
        context "when the are set" do
          let(:options) { { option1: 'value1' } }
          before {
            BigbluebuttonRails.configuration.stub(:get_join_options).and_return(Proc.new{ options })
            room.should_receive(:join_url).with(username, role, nil, options)
          }
          it { room.parameterized_join_url(username, role, nil, {}) }
        end

        context "overrides the options set internally by the method" do
          let(:options) { { option1: 'value1', createTime: 'valid', userID: 'valid' } }
          let(:expected_options) { { option1: 'value1', createTime: 'valid', userID: 'valid' } }
          before {
            BigbluebuttonRails.configuration.stub(:get_join_options).and_return(Proc.new{ options })
            room.should_receive(:join_url).with(username, role, nil, expected_options)
          }
          it { room.parameterized_join_url(username, role, 'invalid', {}) }
        end

        context "calls get_join_options with the correct parameters" do
          context "if the user is passed in the arguments" do
            let(:user) { 'any user' }
            before {
              proc = double(Proc)
              proc.should_receive(:call).with(room, user, {username: username, role: role} )
              BigbluebuttonRails.configuration.should_receive(:get_join_options).and_return(proc)
              room.stub(:join_url)
            }
            it { room.parameterized_join_url(username, role, nil, {}, user) }
          end

          context "if the user is not passed in the arguments" do
            before {
              proc = double(Proc)
              proc.should_receive(:call).with(room, nil, {username: username, role: role} )
              BigbluebuttonRails.configuration.should_receive(:get_join_options).and_return(proc)
              room.stub(:join_url)
            }
            it { room.parameterized_join_url(username, role, nil, {}, nil) }
          end
        end
      end

      context "returns #join_url" do
        let(:expected_url) { 'https://fake-return-url.no/join?here=1' }

        context "with no meetings" do
          let(:room) { create_room_without_meetings }
          it do
            room.should_receive(:join_url)
                .with(username, role, nil, { userID: 'fake-user-id' })
                .and_return(expected_url)
            room.parameterized_join_url(username, role, 'fake-user-id')
                .should eql(expected_url)
          end
        end

        context "with meetings" do
          let(:meetings_count) { 9 }
          let(:room) do
            create_room_with_meetings(meetings_count: meetings_count,
                                      ended: ended)
          end
          context "with no meeting running" do
            let(:ended) { true }
            let(:create_time) { Time.now.to_i }
            it { room.get_current_meeting.should be_nil }
          end
          context "with meeting running" do
            let(:ended) { false }
            let(:create_time) { Time.now.to_i }
            it { room.get_current_meeting.create_time.should be create_time }
          end
        end
      end
    end
  end

  context "#generate_dial_number!" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }

    context "generates the dial number and saves in the room" do
      before {
        BigbluebuttonRoom.stub(:generate_dial_number).and_return("(99) 1234-5678")
        room.generate_dial_number!('x')
      }
      it { room.reload.dial_number.should eql("(99) 1234-5678") }
      it { room.generate_dial_number!('x').should be(true) }
    end

    context "uses the pattern informed" do
      before {
        BigbluebuttonRoom.should_receive(:generate_dial_number).with("(99) 12xx-xxxx")
      }
      it { room.generate_dial_number!("(99) 12xx-xxxx").should be(true) }
    end

    context "returns nil if no pattern is given" do
      it { BigbluebuttonRoom.last.generate_dial_number!.should be(nil) }
    end
  end

  context "#generate_dial_number" do
    context "uses the last room creatd to set dial number" do
      before { BigbluebuttonRoom.last.update_attributes(dial_number: '1234-5678') }
      it { BigbluebuttonRoom.generate_dial_number('x').should eql('1234-5679') }
    end

    context "when the firt room is created" do
      before { BigbluebuttonRoom.first.delete }
      it { BigbluebuttonRoom.generate_dial_number('1234-xxxx').should eql('1234-0000') }
    end

    context "returns nil if no pattern is given" do
      it { BigbluebuttonRoom.generate_dial_number.should be(nil) }
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

    context "when the conference is running" do
      before {
        room.should_receive(:is_running?).and_return(true)
      }
      subject { room.create_meeting(user) }
      it { should be(false) }
    end

    context "when the conference is not running" do
      before {
        room.should_receive(:is_running?).and_return(false)
        room.should_receive(:send_create).with(user)
      }
      subject { room.create_meeting(user) }
      it { should be(true) }
    end

    # use to call end before creating a meeting in previous versions
    context "when the conference is not running doesn't call end" do
      before {
        room.should_receive(:is_running?).and_return(false)
        room.should_receive(:send_create).with(user)
        room.should_not_receive(:send_end)
      }
      subject { room.create_meeting(user) }
      it { should be(true) }
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
      it { should be(true) }
    end
  end

  describe "#full_logout_url" do
    subject { BigbluebuttonRoom.new }
    it { should respond_to(:full_logout_url) }
    it { should respond_to(:"full_logout_url=") }
  end

  describe "#short_path" do
    subject { FactoryGirl.create(:bigbluebutton_room) }
    it { subject.short_path.should eql("/bigbluebutton/rooms/#{subject.to_param}/join") }
  end

  describe "#select_server" do
    let!(:server) { FactoryGirl.create(:bigbluebutton_server) }
    let!(:room) { FactoryGirl.create(:bigbluebutton_room) }

    it { room.respond_to?(:select_server, true).should be(true) }

    context "assigns server to room if there is one" do
      it { room.select_server.should eql(BigbluebuttonServer.first) }
    end

    context "raises exception if there are no servers to assign" do
      before {
        BigbluebuttonServer.destroy_all
      }
      it {
        expect {
          room.select_server
        }.to raise_error(BigbluebuttonRails::ServerRequired)
      }
    end
  end

  describe "#get_metadata_for_create" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }

    context "returns the metadata from the database" do
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

  describe "#get_current_meeting" do
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }

    context "when there's no meeting" do
      let(:room) { create_room_without_meetings }
      it { room.get_current_meeting.should be_nil }
    end

    context 'when there are meetings' do
      let(:room) do
        create_room_with_meetings(meetings_count: meetings_count,
                                  ended: ended,
                                  create_time: create_time)
      end
      context 'when the meeting has not ended' do
        let(:ended) { false }
        let(:meetings_count) { 11 }
        let(:create_time) { Time.now.to_i + 123 }
        it { room.get_current_meeting.should eql room.meetings.last }
        it { room.get_current_meeting.create_time.should eql create_time }
        it { room.get_current_meeting.running.should eql true }
      end
      context 'when the meeting has ended' do
        let(:ended) { true }
        let(:meetings_count) { 12 }
        let(:create_time) { Time.now.to_i + 234 }
        it { room.get_current_meeting.should be_nil }
      end
    end
  end

  describe "#update_current_meeting_record" do
    context "if #create_time is set" do
      let(:user) { FactoryGirl.build(:user) }
      let(:create_time) { Time.now.to_i - 123 }
      let(:running) { false }
      let(:response) {
        r = {}
        r[:createTime] = create_time
        r[:running] = running
        r[:metadata] = {}
        r[:metadata][BigbluebuttonRails.configuration.metadata_user_id] = user.id
        r[:metadata][BigbluebuttonRails.configuration.metadata_user_name] = user.name
        r
      }

      context "and no metadata was passed" do
        let(:response) {
          r = {}
          r[:createTime] = create_time
          r[:running] = running
          r
        }

        context "when there's no meeting" do
          let(:room) { create_room_without_meetings }
          before(:each) {
            room
            expect {
              room.update_current_meeting_record(response)
            }.not_to change{ BigbluebuttonMeeting.count }
          }
        end
        context 'when there are meetings' do
          context 'when the meeting has not ended' do
            let(:room) do
              create_room_with_meetings(ended: false,
                                        meetings_count: 13,
                                        create_time: Time.now.to_i + 345)
            end
            before(:each) do
              room
              expect {
                room.update_current_meeting_record(response)
              }.not_to change{ BigbluebuttonMeeting.count }
            end
            it("sets running") { room.get_current_meeting.running.should eq(response[:running]) }
            it("sets create_time") { room.get_current_meeting.create_time.should eq(response[:createTime]) }
            it("doesn't set creator_id") { room.get_current_meeting.creator_id.should be_nil }
            it("doesn't set creator_name") { room.get_current_meeting.creator_name.should be_nil }
          end
          context 'when the meeting has ended' do
            let(:room) do
              create_room_with_meetings(ended: true,
                                        meetings_count: 14,
                                        create_time: Time.now.to_i + 567)
            end
            before(:each) do
              room
              expect {
                room.update_current_meeting_record(response)
              }.not_to change{ BigbluebuttonMeeting.count }
            end
            it { expect(room.get_current_meeting).to be_nil}
          end
        end
      end

      context "and metadata was passed" do
        context "when there's no meeting" do
          let(:room) { create_room_without_meetings }
          before(:each) do
            room
            expect { room.update_current_meeting_record(response) }
            .not_to change{ BigbluebuttonMeeting.count }
          end
        end
        context 'when there are meetings' do
          context 'when the meeting has not ended' do
            let(:room) do
              create_room_with_meetings(ended: false,
                                        meetings_count: 12,
                                        create_time: Time.now.to_i + 345)
            end
            before(:each) do
              room
              expect { room.update_current_meeting_record(response) }
              .not_to change{ BigbluebuttonMeeting.count }
            end
            it("sets running") { room.get_current_meeting.running.should eq(running) }
            it("sets create_time") { room.get_current_meeting.create_time.should eq(response[:createTime]) }
            it("sets creator_id") { room.get_current_meeting.creator_id.should eq(user.id) }
            it("sets creator_name") { room.get_current_meeting.creator_name.should eq(user.name) }
          end
          context 'when the meeting has ended' do
            let(:room) do
              create_room_with_meetings(ended: true,
                                        meetings_count: 13,
                                        create_time: Time.now.to_i + 456)
            end
            before(:each) do
              room
              expect { room.update_current_meeting_record(response) }
              .not_to change{ BigbluebuttonMeeting.count }
            end
            it { room.get_current_meeting.should be_nil }
          end
        end
      end

      context "if force_not_ended is set" do
        context "when there's no meeting" do
          let(:room) { create_room_without_meetings }
          before(:each) do
            room
            expect { room.update_current_meeting_record(response) }
            .not_to change{ BigbluebuttonMeeting.count }
          end
        end
        context 'when there are meetings' do
          context 'when the meeting has not ended' do
            let(:create_time) { Time.now.to_i + 567 }
            let(:room) do
              create_room_with_meetings(ended: false,
                                        meetings_count: 14,
                                        create_time: create_time)
            end
            before(:each) do
              room
              expect { room.update_current_meeting_record(nil, true) }
              .not_to change{ BigbluebuttonMeeting.count }
            end
            it("sets running") { room.get_current_meeting.running.should eq(true) }
            it("sets create_time") { room.get_current_meeting.create_time.should eq(create_time) }
            it("sets ended") { room.get_current_meeting.ended.should be(false) }
          end
          context 'when the meeting has ended' do
            let(:room) do
              create_room_with_meetings(ended: true,
                                        meetings_count: 15,
                                        create_time: Time.now.to_i + 567)
            end
            before(:each) do
              room
              expect { room.update_current_meeting_record(nil, true) }
              .not_to change{ BigbluebuttonMeeting.count }
            end
            it { room.get_current_meeting.should be_nil }
          end
        end
      end
    end
  end

  describe "#finish_meetings" do
    let!(:room) { FactoryGirl.create(:bigbluebutton_room) }

    context "finishes all meetings related to this room that are still not ended" do
      let!(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: false, running: true) }
      let!(:meeting2) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: false, running: true) }
      let!(:meeting3) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: false, running: false) }
      before(:each) { room.finish_meetings }
      it { meeting1.reload.running.should be(false) }
      it { meeting1.reload.ended.should be(true) }
      it { meeting2.reload.running.should be(false) }
      it { meeting2.reload.ended.should be(true) }
      it { meeting3.reload.running.should be(false) }
      it { meeting3.reload.ended.should be(true) }
    end

    context "works if the room has no meetings" do
      it { room.finish_meetings }
    end

    context "if there's a current meeting not running, ends it" do
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: false, running: false, create_time: Time.now) }
      let!(:now) { DateTime.now }
      before(:each) {
        DateTime.stub(:now).and_return(now)
        room.finish_meetings
      }
      it { meeting.reload.running.should be(false) }
      it { meeting.reload.ended.should be(true) }
      it { meeting.reload.finish_time.should be(now.strftime("%Q").to_i) }
    end

    context "ends meetings are already ended but still set as running" do
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: true, running: true) }
      let!(:now) { DateTime.now }
      before(:each) {
        DateTime.stub(:now).and_return(now)
        room.finish_meetings
      }
      it { meeting.reload.running.should be(false) }
      it { meeting.reload.ended.should be(true) }
      it { meeting.reload.finish_time.should be(now.strftime("%Q").to_i) }
    end

    context "enqueues workers to fetch recordings" do
      context "if at least one meeting was ended" do
        let!(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: false, running: true) }
        let!(:meeting2) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: false, running: true) }
        before {
          tries = BigbluebuttonRails.configuration.recording_sync_for_room_intervals.length - 1
          expect(Resque).to receive(:enqueue_in).with(1.minute, ::BigbluebuttonRecordingsForRoomWorker, room.id, tries)
        }
        it { room.finish_meetings }
      end

      context "not if no meeting was ended" do
        let!(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: true, running: true) }
        before {
          expect(Resque).not_to receive(:enqueue_in)
        }
        it { room.finish_meetings }
      end
    end
  end

  describe "#internal_create_meeting" do
    it "creates the correct hash of parameters"
    it "adds metadata with the user's id"
    it "adds metadata with the user's name"
    it "sets the request headers"
    it "calls api.create_meeting"
    it "accepts additional user options to override the options in the database"
    it "returns the server selected and the response"

    context "adds the invitation URL, if any" do
      before { mock_server_and_api }
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }

      before {
        room.stub(:select_server).and_return(mocked_server)
        mocked_api.stub(:"request_headers=")
      }

      it { room.should_not respond_to(:invitation_url) }

      context "doesn't add the invitation URL by default" do
        before {
          mocked_api.should_receive(:create_meeting) do |name, meetingid, opts|
            opts.should_not have_key('meta_invitation-url')
            opts.should_not have_key(:'meta_invitation-url')
          end
        }
        it { room.send(:internal_create_meeting) }
      end

      context "doesn't add the invitation URL if BigbluebuttonRoom#invitation_url returns nil" do
        before {
          BigbluebuttonRails.configure do |config|
            config.get_invitation_url = Proc.new do |room|
              nil
            end
          end

          mocked_api.should_receive(:create_meeting) do |name, meetingid, opts|
            opts.should_not have_key('meta_invitation-url')
            opts.should_not have_key(:'meta_invitation-url')
          end
        }

        it { room.send(:internal_create_meeting) }
      end

      context "adds the invitation_url" do
        before {
          BigbluebuttonRails.configure do |config|
            config.get_invitation_url = Proc.new do |room|
              'http://my-invitation.url'
            end
          end

          mocked_api.should_receive(:create_meeting) do |name, meetingid, opts|
            opts.should include('meta_invitation-url' => 'http://my-invitation.url')
          end
        }

        it { room.send(:internal_create_meeting) }
      end
    end

    context "adds the options from user_opts" do
      before { mock_server_and_api }
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let(:user_opts) { { "meta_test1" => "value1", "meta_test2" => "value2" } }
      before {
        room.stub(:select_server).and_return(mocked_server)
        mocked_api.stub(:"request_headers=")

        mocked_api.should_receive(:create_meeting) do |name, meetingid, opts|
          opts.should include('meta_test1' => 'value1')
          opts.should include('meta_test2' => 'value2')
        end
      }

      it { room.send(:internal_create_meeting, nil, user_opts) }
    end
  end

  describe "#fetch_recordings" do
    let!(:server) { FactoryGirl.create(:bigbluebutton_server) }
    let!(:room) { FactoryGirl.create(:bigbluebutton_room) }

    it { should respond_to(:fetch_recordings) }

    context "if no server is found" do
      before {
        room.stub(:select_server).and_return(nil)
        server.should_not_receive(:fetch_recordings)
      }

      it { room.fetch_recordings.should be(false) }
    end

    context "if a server is found" do
      before {
        room.stub(:select_server).and_return(server)
        filter = { meetingID: room.meetingid, state: BigbluebuttonRecording::STATES.values }
        scope = BigbluebuttonRecording.where(room: room, state: BigbluebuttonRecording::STATES.values)
        server.should_receive(:fetch_recordings).with(filter, scope)
      }

      it { room.fetch_recordings.should be(true) }
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
    :moderatorOnlyMessage => room.moderator_only_message,
    :autoStartRecording => room.auto_start_recording,
    :allowStartStopRecording => room.allow_start_stop_recording
  }
  unless user.nil?
    userid = user.send(:id)
    username = user.send(:name)
    params.merge!({ "meta_bbbrails-user-id" => userid })
    params.merge!({ "meta_bbbrails-user-name" => username })
  end
  room.metadata.each { |meta| params["meta_#{meta.name}"] = meta.content }
  params
end
