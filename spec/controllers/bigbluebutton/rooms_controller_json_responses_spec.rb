require 'spec_helper'

describe Bigbluebutton::RoomsController do
  render_views
  let(:server) { Factory.create(:bigbluebutton_server) }
  let(:room) { Factory.create(:bigbluebutton_room, :server => server) }

  context "json responses for " do

    describe "#index" do
      before do
        @room1 = Factory.create(:bigbluebutton_room, :server => server)
        @room2 = Factory.create(:bigbluebutton_room, :server => server)
      end
      before(:each) { get :index, :server_id => server.to_param, :format => 'json' }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should respond_with_json([@room1, @room2].to_json) }
    end

    describe "#new" do
      before(:each) { get :new, :server_id => server.to_param, :format => 'json' }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it {
        # we ignore all values bc a BigbluebuttonRoom is generated with some
        # random values (meetingid, voice_bridge)
        should respond_with_json(BigbluebuttonRoom.new.to_json).ignoring_values
      }
    end

    describe "#show" do
      before(:each) { get :show, :server_id => server.to_param, :id => room.to_param, :format => 'json' }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should respond_with_json(room.to_json) }
    end

    describe "#create" do
      let(:new_room) { Factory.build(:bigbluebutton_room, :server => server) }

      context "on success" do
        before(:each) {
          post :create, :server_id => server.to_param, :bigbluebutton_room => new_room.attributes, :format => 'json'
        }
        it { should respond_with(:created) }
        it { should respond_with_content_type(:json) }
        it {
          json = { :message => I18n.t('bigbluebutton_rails.rooms.notice.create.success') }.to_json
          should respond_with_json(json)
        }
      end

      context "on failure" do
        before(:each) {
          new_room.name = nil # invalid
          post :create, :server_id => server.to_param, :bigbluebutton_room => new_room.attributes, :format => 'json'
        }
        it { should respond_with(:unprocessable_entity) }
        it { should respond_with_content_type(:json) }
        it {
          new_room.save # should fail
          should respond_with_json(new_room.errors.full_messages.to_json)
        }
      end
    end

    describe "#update" do
      let(:new_room) { Factory.build(:bigbluebutton_room) }
      before { @room = room }

      context "on success" do
        before(:each) {
          put :update, :server_id => server.to_param, :id => @room.to_param, :bigbluebutton_room => new_room.attributes, :format => 'json'
        }
        it { should respond_with(:success) }
        it { should respond_with_content_type(:json) }
        it {
          json = { :message => I18n.t('bigbluebutton_rails.rooms.notice.update.success') }.to_json
          should respond_with_json(json)
        }
      end

      context "on failure" do
        before(:each) {
          new_room.name = nil # invalid
          put :update, :server_id => server.to_param, :id => @room.to_param, :bigbluebutton_room => new_room.attributes, :format => 'json'
        }
        it { should respond_with(:unprocessable_entity) }
        it { should respond_with_content_type(:json) }
        it {
          new_room.save # should fail
          should respond_with_json(new_room.errors.full_messages.to_json)
        }
      end
    end

    describe "#end" do
      before { mock_server_and_api }

      context "room is running" do
        before {
          mocked_api.should_receive(:is_meeting_running?).and_return(true)
          mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_password)
        }
        before(:each) { get :end, :server_id => mocked_server.to_param, :id => room.to_param, :format => 'json' }
        it { should respond_with(:success) }
        it { should respond_with_content_type(:json) }
        it { should respond_with_json(I18n.t('bigbluebutton_rails.rooms.notice.end.success')) }
      end

      context "room is not running" do
        before { mocked_api.should_receive(:is_meeting_running?).and_return(false) }
        before(:each) { get :end, :server_id => mocked_server.to_param, :id => room.to_param, :format => 'json' }
        it { should respond_with(:error) }
        it { should respond_with_content_type(:json) }
        it { should respond_with_json(I18n.t('bigbluebutton_rails.rooms.notice.end.not_running')) }
      end

      context "throwing an exception" do
        let(:msg) { "any error message" }
        before {
          mocked_api.should_receive(:is_meeting_running?).and_return{ raise BigBlueButton::BigBlueButtonException.new(msg) }
        }
        before(:each) { get :end, :server_id => mocked_server.to_param, :id => room.to_param, :format => 'json' }
        it { should respond_with(:error) }
        it { should respond_with_content_type(:json) }
        it { should respond_with_json(msg) }
      end

    end

    describe "#destroy" do
      before { mock_server_and_api }

      context "on success" do
        before {
          mocked_api.should_receive(:is_meeting_running?).and_return(true)
          mocked_api.should_receive(:end_meeting)
        }
        before(:each) {
          delete :destroy, :server_id => mocked_server.to_param, :id => room.to_param, :format => 'json'
        }
        it { should respond_with(:success) }
        it { should respond_with_content_type(:json) }
        it {
          json = { :message => I18n.t('bigbluebutton_rails.rooms.notice.destroy.success') }.to_json
          should respond_with_json(json)
        }
      end

      context "throwing error" do
        let(:msg) { "any error message" }
        before {
          mocked_api.should_receive(:is_meeting_running?).and_return{ raise BigBlueButton::BigBlueButtonException.new(msg) }
        }
        before(:each) {
          delete :destroy, :server_id => mocked_server.to_param, :id => room.to_param, :format => 'json'
        }
        it { should respond_with(:error) }
        it { should respond_with_content_type(:json) }
        it { should respond_with_json({ :message => msg }.to_json) }
      end
    end

  end
end
