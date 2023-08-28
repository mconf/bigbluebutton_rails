require 'spec_helper'

describe BigbluebuttonRails::BackgroundTasks do

  describe ".finish_meetings" do
    let!(:api) { double(BigBlueButton::BigBlueButtonApi) }
    let!(:server) { FactoryBot.create(:bigbluebutton_server) }

    context "set meetings that ended as not running and ended" do
      let(:room) { FactoryBot.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryBot.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      let!(:exception) {
        e = BigBlueButton::BigBlueButtonException.new('Test error')
        e.key = 'notFound'
        e
      }

      before {
        BigBlueButton::BigBlueButtonApi.any_instance
          .stub(:get_api_version).and_return("0.9")
        BigBlueButton::BigBlueButtonApi.any_instance
          .should_receive(:get_meeting_info).once { raise exception }
      }
      before(:each) { BigbluebuttonRails::BackgroundTasks.finish_meetings }
      it { meeting.reload.running.should be(false) }
      it { meeting.reload.ended.should be(true) }
    end

    context "doesn't change meetings that are still running" do
      let(:room) { FactoryBot.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryBot.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      before {
        BigBlueButton::BigBlueButtonApi.any_instance
          .stub(:get_api_version).and_return("0.9")
        BigBlueButton::BigBlueButtonApi.any_instance
          .should_receive(:get_meeting_info).once.and_return({ running: true })
      }
      before(:each) { BigbluebuttonRails::BackgroundTasks.finish_meetings }
      it { meeting.reload.running.should be(true) }
      it { meeting.reload.ended.should be(false) }
    end

    context "ignores meetings that already ended" do
      let(:room) { FactoryBot.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryBot.create(:bigbluebutton_meeting, ended: true, room: room) }
      before(:each) {
        BigbluebuttonRoom.any_instance.should_not_receive(:fetch_meeting_info)
        BigbluebuttonRails::BackgroundTasks.finish_meetings
      }
      it { meeting.reload.running.should be(false) }
    end

    context "considers both meetings running and not running" do
      let(:room1) { FactoryBot.create(:bigbluebutton_room) }
      let(:room2) { FactoryBot.create(:bigbluebutton_room) }
      let!(:meeting1) { FactoryBot.create(:bigbluebutton_meeting, ended: false, running: true, room: room1) }
      let!(:meeting2) { FactoryBot.create(:bigbluebutton_meeting, ended: false, running: false, room: room2) }
      let!(:exception) {
        e = BigBlueButton::BigBlueButtonException.new('Test error')
        e.key = 'notFound'
        e
      }

      before {
        BigBlueButton::BigBlueButtonApi.any_instance
          .stub(:get_api_version).and_return("0.9")
        BigBlueButton::BigBlueButtonApi.any_instance.stub(:get_meeting_info) { raise exception }
      }
      before(:each) { BigbluebuttonRails::BackgroundTasks.finish_meetings }
      it { meeting1.reload.running.should be(false) }
      it { meeting1.reload.ended.should be(true) }
      it { meeting1.reload.running.should be(false) }
      it { meeting1.reload.ended.should be(true) }
    end

    context "ignore meetings that have no room" do
      let(:room) { FactoryBot.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryBot.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      before(:each) {
        BigbluebuttonRoom.any_instance.should_not_receive(:fetch_meeting_info)
        meeting.room.delete
        BigbluebuttonRails::BackgroundTasks.finish_meetings
      }
      it { meeting.reload.running.should be(true) }
    end

    context "calls finish_meetings if an exception 'notFound' is raised" do
      let!(:room) { FactoryBot.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryBot.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      let!(:exception) {
        e = BigBlueButton::BigBlueButtonException.new('Test error')
        e.key = 'notFound'
        e
      }

      before {
        BigbluebuttonServer.any_instance.should_receive(:api) { api }
        expect(api).to receive(:get_meeting_info).once { raise exception }
        BigbluebuttonRoom.any_instance.should_receive(:finish_meetings).once
      }
      it { expect { BigbluebuttonRails::BackgroundTasks.finish_meetings }.not_to raise_exception }
    end

    context "calls finish_meetings if an exception other than 'notFound' is raised" do
      let!(:room) { FactoryBot.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryBot.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      let!(:exception) {
        e = BigBlueButton::BigBlueButtonException.new('Test error')
        e.key = 'anythingElse'
        e
      }

      before {
        BigbluebuttonServer.any_instance.should_receive(:api) { api }
        expect(api).to receive(:get_meeting_info).once { raise exception }
        BigbluebuttonRoom.any_instance.should_receive(:finish_meetings)
      }
      it { expect { BigbluebuttonRails::BackgroundTasks.finish_meetings }.not_to raise_exception }
    end

    context "calls finish_meetings if an exception with a blank key is raised" do
      let!(:room) { FactoryBot.create(:bigbluebutton_room) }
      let!(:meeting) { FactoryBot.create(:bigbluebutton_meeting, ended: false, running: true, room: room) }
      let!(:exception) {
        e = BigBlueButton::BigBlueButtonException.new('Test error')
        e.key = ''
        e
      }

      before {
        BigbluebuttonServer.any_instance.should_receive(:api) { api }
        expect(api).to receive(:get_meeting_info).once { raise exception }
        BigbluebuttonRoom.any_instance.should_receive(:finish_meetings)
      }
      it { expect { BigbluebuttonRails::BackgroundTasks.finish_meetings }.not_to raise_exception }
    end
  end

  describe ".update_recordings_by_server" do
    let!(:server1) { FactoryBot.create(:bigbluebutton_server) }
    let!(:server2) { FactoryBot.create(:bigbluebutton_server) }

    context "fetches the recordings for all servers if none is informed" do
      before {
        BigbluebuttonServer.stub(:find_each).and_yield(server1).and_yield(server2)
        server1.should_receive(:fetch_recordings).once.with(no_args)
        server2.should_receive(:fetch_recordings).once.with(no_args)
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings_by_server }
    end

    context "fetches the recordings for the server informed" do
      before {
        BigbluebuttonServer.stub(:find_each).and_yield(server1).and_yield(server2)
        server1.should_receive(:fetch_recordings).once.with(no_args)
        server2.should_not_receive(:fetch_recordings)
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings_by_server(server1) }
    end

    context "doesn't break if exceptions happen in one of the requests" do
      before {
        BigbluebuttonServer.stub(:find_each).and_yield(server1).and_yield(server2)
        server1.should_receive(:fetch_recordings).once.with(no_args) { raise IncorrectUrlError.new }
        server2.should_receive(:fetch_recordings).once.with(no_args)
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings_by_server }
    end
  end

  describe ".update_recordings_by_room" do
    let!(:room1) { FactoryBot.create(:bigbluebutton_room) }
    let!(:room2) { FactoryBot.create(:bigbluebutton_room) }
    let!(:room3) { FactoryBot.create(:bigbluebutton_room) }

    context "fetches the recordings for all rooms if no query is informed" do
      before {
        BigbluebuttonRoom.stub(:find_each).and_yield(room1).and_yield(room2).and_yield(room3)
        room1.should_receive(:fetch_recordings).once.with(no_args)
        room2.should_receive(:fetch_recordings).once.with(no_args)
        room3.should_receive(:fetch_recordings).once.with(no_args)
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings_by_room }
    end

    context "fetches the recordings for the rooms using the query informed" do
      let(:query) { BigbluebuttonRoom.where(id: room2.id) }
      before {
        BigbluebuttonRoom.stub(:find_each).and_yield(room1).and_yield(room2).and_yield(room3)
        query.stub(:find_each).and_yield(room2)
        room1.should_not_receive(:fetch_recordings)
        room2.should_receive(:fetch_recordings).once.with(no_args)
        room3.should_not_receive(:fetch_recordings)
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings_by_room(query) }
    end

    context "doesn't break if exceptions happen in one of the requests" do
      before {
        BigbluebuttonRoom.stub(:find_each).and_yield(room1).and_yield(room2).and_yield(room3)
        room1.should_receive(:fetch_recordings).once.with(no_args) { raise IncorrectUrlError.new }
        room2.should_receive(:fetch_recordings).once.with(no_args)
        room3.should_receive(:fetch_recordings).once.with(no_args)
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings_by_room }
    end
  end

  describe ".update_recordings_for_server" do
    let!(:server) { FactoryBot.create(:bigbluebutton_server) }

    context "fetches the recordings the server passed" do
      before {
        server.should_receive(:fetch_recordings).once.with(no_args)
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings_for_server(server) }
    end

    context "rescues from exceptions" do
      before {
        server.should_receive(:fetch_recordings).once.with(no_args) { raise IncorrectUrlError.new }
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings_for_server(server) }
    end
  end

  describe ".update_recordings_for_room" do
    let!(:room) { FactoryBot.create(:bigbluebutton_room) }

    context "fetches the recordings the room passed" do
      before {
        room.should_receive(:fetch_recordings).once.with(no_args)
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings_for_room(room) }
    end

    context "rescues from exceptions" do
      before {
        room.should_receive(:fetch_recordings).once.with(no_args) { raise IncorrectUrlError.new }
      }
      it { BigbluebuttonRails::BackgroundTasks.update_recordings_for_room(room) }
    end
  end
end
