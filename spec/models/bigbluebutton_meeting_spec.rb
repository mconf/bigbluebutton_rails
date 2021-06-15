# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonMeeting do
  it "loaded correctly" do
    BigbluebuttonMeeting.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_meeting) }

  it { should belong_to(:room) }
  it { should validate_presence_of(:room) }

  it { should have_one(:recording).dependent(:destroy) }

  describe "recording association" do
    let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, ended: true) }
    let!(:recording) { FactoryGirl.create(:bigbluebutton_recording, meeting: meeting) }

    context "when the meeting is successfully destroyed" do
      before do
        expect(BigbluebuttonMeeting.where(id: meeting.id).count).to eq(1)
        expect(BigbluebuttonRecording.where(meeting_id: meeting.id).count).to eq(1)
        BigbluebuttonServer.any_instance.stub(:send_delete_recordings).and_return(true)
      end

      it "should destroy the meeting and the associated recording" do
        meeting.destroy
        expect(BigbluebuttonMeeting.where(id: meeting.id).count).to eq(0)
        expect(BigbluebuttonRecording.where(meeting_id: meeting.id).count).to eq(0)
      end
    end

    context "when the meeting fails to be destroyed" do
      before do
        expect(BigbluebuttonMeeting.where(id: meeting.id).count).to eq(1)
        expect(BigbluebuttonRecording.where(meeting_id: meeting.id).count).to eq(1)
        BigbluebuttonServer.any_instance.stub(:send_delete_recordings).and_return(false)
      end
      it "should not destroy the meeting nor the associated recording" do
        meeting.destroy
        expect(BigbluebuttonMeeting.where(id: meeting.id).count).to eq(1)
        expect(BigbluebuttonRecording.where(meeting_id: meeting.id).count).to eq(1)
      end
    end
  end

  it { should validate_presence_of(:meetingid) }
  it { should ensure_length_of(:meetingid).is_at_least(1).is_at_most(100) }

  it { should validate_presence_of(:create_time) }
  it { should validate_uniqueness_of(:create_time).scoped_to(:room_id) }


  describe "#created_by?" do
    let(:target) { FactoryGirl.create(:bigbluebutton_meeting) }

    context "if the user informed is nil" do
      it { target.created_by?(nil).should be_falsey }
    end

    context "with a valid user informed" do
      let(:user) { FactoryGirl.build(:user) }

      context "if the meeting has no creator_id" do
        before { target.update_attributes(:creator_id => nil) }
        it { target.created_by?(user).should be_falsey }
      end

      context "if it wasn't the user that created the meeting" do
        let(:user2) { FactoryGirl.build(:user) }
        before { target.update_attributes(:creator_id => user2.id, :creator_name => user2.name) }
        it { target.created_by?(user).should be_falsey }
      end

      context "if it was the user that created the meeting" do
        before { target.update_attributes(:creator_id => user.id, :creator_name => user.name) }
        it { target.created_by?(user).should be_truthy }
      end
    end
  end

  describe ".create_meeting_record_from_room" do
    let(:server) { FactoryGirl.create(:bigbluebutton_server) }
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }

    context "if there is already a current meeting" do
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: false, running: true, create_time: room.create_time) }
      subject {
        expect {
          BigbluebuttonMeeting.create_meeting_record_from_room(room, {}, server, nil, {})
        }.not_to change{ BigbluebuttonMeeting.count }
      }
      it { BigbluebuttonMeeting.where(room: room).count.should be(1) }
      it { meeting.reload.running.should be(true) }
      it { meeting.reload.ended.should be(false) }
    end

    context "if #create_time is not set in the room" do
      before { room.update_attributes(create_time: nil) }
      subject { BigbluebuttonMeeting.create_meeting_record_from_room(room, {}, server, nil, {}) }
      it("doesn't create a meeting") {
        BigbluebuttonMeeting.find_by(room_id: room.id).should be_nil
      }
    end

    context "if #create_time is set" do
      let(:user) { FactoryGirl.build(:user) }
      let(:metadata) {
        m = {}
        m[BigbluebuttonRails.configuration.metadata_user_id] = user.id
        m[BigbluebuttonRails.configuration.metadata_user_name] = user.name
        m
      }
      before {
        room.create_time = Time.now.utc
        room.running = !room.running # to change its default value
        room.record_meeting = !room.record_meeting # to change its default value
        room.create_time = Time.at(Time.now.to_i - 123)  # to change its default value
      }

      context "if there's no meeting associated yet creates one" do
        context "and there's no metadata in the response" do
          before(:each) {
            expect {
              BigbluebuttonMeeting.create_meeting_record_from_room(room, {internalMeetingID: 'fake-id'}, server, nil, {})
            }.to change{ BigbluebuttonMeeting.count }.by(1)
          }
          subject { BigbluebuttonMeeting.last }
          it("sets server_url") { subject.server_url.should eq(server.url) }
          it("sets server_secret") { subject.server_secret.should eq(server.secret) }
          it("sets room") { subject.room.should eq(room) }
          it("sets meetingid") { subject.meetingid.should eq(room.meetingid) }
          it("sets name") { subject.name.should eq(room.name) }
          it("sets recorded") { subject.recorded.should eq(room.record_meeting) }
          it("sets running") { subject.running.should eq(room.running) }
          it("sets create_time") { subject.create_time.should eq(room.create_time.to_i) }
          it("doesn't set creator_id") { subject.creator_id.should be_nil }
          it("doesn't set creator_name") { subject.creator_name.should be_nil }
          it("sets internal_meeting_id") { subject.internal_meeting_id.should eq('fake-id') }
        end

        context "and there's metadata in the response" do
          before(:each) {
            expect {
              BigbluebuttonMeeting.create_meeting_record_from_room(room, { metadata: metadata }, server, nil, {})
            }.to change{ BigbluebuttonMeeting.count }.by(1)
          }
          subject { BigbluebuttonMeeting.last }
          it("sets creator_id") { subject.creator_id.should eq(user.id) }
          it("sets creator_name") { subject.creator_name.should eq(user.name) }
        end

        context "and there are user attributes" do
          let(:user_attrs) {
            {
              meetingID: room.meetingid + "-2",
              name: room.name + "-2",
              record: false, # important to be false here
              creator_name: "can override the creator name",
              creator_id: -10
            }
          }
          before {
            room.record_meeting = true
            expect {
              BigbluebuttonMeeting.create_meeting_record_from_room(room, {internal_meeting_id: 'fake-id'}, server, nil, user_attrs)
            }.to change{ BigbluebuttonMeeting.count }.by(1)
          }
          subject { BigbluebuttonMeeting.last }
          it("sets meetingid") { subject.meetingid.should eql(room.meetingid + '-2') }
          it("sets name") { subject.name.should eql(room.name + '-2') }
          it("sets recorded") { subject.recorded.should be(false) }
          it("sets creator name") { subject.creator_name.should eql("can override the creator name") }
          it("sets creator id") { subject.creator_id.should eql(-10) }
        end
      end

      context "if there were already old meetings associated with the room, finishes them" do
        let!(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: false, running: true) }
        let!(:meeting2) { FactoryGirl.create(:bigbluebutton_meeting, room: room, ended: false, running: false) }

        before(:each) {
          BigbluebuttonMeeting.where(room: room, ended: false).count.should be(2)
          expect {
            BigbluebuttonMeeting.create_meeting_record_from_room(room, { metadata: metadata }, server, nil, {})
          }.to change{ BigbluebuttonMeeting.count }.by(1)
        }
        it { BigbluebuttonMeeting.where(room: room).count.should be(3) }
        it { BigbluebuttonMeeting.where(room: room, ended: false).count.should be(1) }
        it { BigbluebuttonMeeting.where(room: room, ended: true).count.should be(2) }
        it { BigbluebuttonMeeting.where(room: room, ended: true, running: false).count.should be(2) }
      end
    end
  end

  describe ".create_meeting_record_from_recording" do
    let(:server) { FactoryGirl.create(:bigbluebutton_server) }
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }
    let!(:recording1) { FactoryGirl.create(:bigbluebutton_recording, meeting_id: nil, server_id: server.id, room_id: room.id) }
    let!(:recording2) { FactoryGirl.create(:bigbluebutton_recording, meeting_id: nil, server_id: server.id, room_id: nil, name: "no_room") }
    
    context "when there is a room_id on the recording" do
      before(:each) {
        expect {
          BigbluebuttonMeeting.create_meeting_record_from_recording(recording1)
        }.to change{ BigbluebuttonMeeting.count }.by(1)
      }
      subject { BigbluebuttonMeeting.last }
      it("sets room") { subject.room.should eq(recording1.room) }
      it("sets meetingid") { subject.meetingid.should eq(recording1.meetingid) }
      it("sets name") { subject.name.should eq(recording1.name) }
      it("sets running") { subject.running.should eq(false) }
      it("sets recorded") { subject.recorded.should eq(true) }
      it("doesn't set creator_id") { subject.creator_id.should be_nil }
      it("doesn't set creator_name") { subject.creator_name.should be_nil }
      it("sets server_url") { subject.server_url.should eq(recording1.server.url) }
      it("sets server_secret") { subject.server_secret.should eq(recording1.server.secret) }
      it("sets create_time") { subject.create_time.should eq(recording1.start_time * 1000) }   
      it("sets ended") { subject.recorded.should eq(true) }
      it("sets finish_time") { subject.finish_time.should eq(recording1.end_time) }
      it("sets title") { subject.title.should eq(recording1.name) }
      it("sets internal_meeting_id") { subject.internal_meeting_id.should eq(recording1.recordid) }
    end

    context "when there isn't a room_id on the recording" do
      it("doesn't create a meeting") {
        BigbluebuttonMeeting.create_meeting_record_from_recording(recording2)
        BigbluebuttonMeeting.find_by(name: "no_room").should be_nil
      }
    end
  end

  describe ".update_meeting_creator" do   
    let(:meeting1) { FactoryGirl.create(:bigbluebutton_meeting, creator_name: nil, creator_id: nil) }
    let(:recording1) { FactoryGirl.create(:bigbluebutton_recording, meeting: meeting1) }
    let(:recording2) { FactoryGirl.create(:bigbluebutton_recording, meeting: meeting1) }
    let!(:metadata1) { FactoryGirl.create(:bigbluebutton_metadata, name: 'bbbrails-user-name', content: 'BbbUserName', owner: recording1) }
    let!(:metadata2) { FactoryGirl.create(:bigbluebutton_metadata, name: 'bbbrails-user-id', content: 21, owner: recording1) }
    context "when the recording has the needed metadata" do
      before { BigbluebuttonMeeting.update_meeting_creator(recording1) }
      it("the meeting's creator_name should be updated with the recording's metadata bbbrails-user-name") {
        meeting1.creator_name.should eq(metadata1.content)
      }
      it("the meeting's creator_id should be updated with the recording's metadata bbbrails-user-id") {
        meeting1.creator_id.should eq(metadata2.content)
      }
    end

    context "when the recording does not have metadata" do
      before { BigbluebuttonMeeting.update_meeting_creator(recording2) }
      it("the meeting's creator_nane should be nil") { meeting1.creator_name.should eq(nil) }
      it("the meeting's creator_id should be nil")  { meeting1.creator_id.should eq(nil) }
    end
  end
end
