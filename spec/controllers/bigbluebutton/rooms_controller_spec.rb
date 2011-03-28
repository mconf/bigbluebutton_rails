require 'spec_helper'
require 'bigbluebutton-api'

describe Bigbluebutton::RoomsController do

  render_views
  let(:server) { Factory.create(:bigbluebutton_server) }
  let(:room) { Factory.create(:bigbluebutton_room, :server => server) }

  describe "#index" do
    before(:each) { get :index, :server_id => server.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
    it { should assign_to(:rooms).with(BigbluebuttonRoom.all) }
  end

  describe "#show" do
    before(:each) { get :show, :server_id => server.to_param, :id => room.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
    it { should assign_to(:room).with(room) }
  end

  describe "#new" do
    before(:each) { get :new, :server_id => server.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
    it { should assign_to(:room).with_kind_of(BigbluebuttonRoom) }
  end

  describe "#edit" do
    before(:each) { get :edit, :server_id => server.to_param, :id => room.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
    it { should assign_to(:room).with(room) }
  end

  describe "#create" do
    before :each do
      expect {
        post :create, :server_id => server.to_param, :bigbluebutton_room => Factory.attributes_for(:bigbluebutton_room)
      }.to change{ BigbluebuttonRoom.count }.by(1)
    end
    it {
      should respond_with(:redirect)
      should redirect_to(bigbluebutton_server_room_path(server, BigbluebuttonRoom.last))
    }
    it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.successfully_created')) }
    it { should assign_to(:server).with(server) }
  end

  describe "#update" do
    let(:new_room) { Factory.build(:bigbluebutton_room) }
    before :each do
      @room = room
      expect {
        put :update, :server_id => server.to_param, :id => @room.to_param, :bigbluebutton_room => new_room.attributes
      }.not_to change{ BigbluebuttonRoom.count }
    end
    it {
      should respond_with(:redirect)
      should redirect_to(bigbluebutton_server_room_path(server, @room))
    }
    it {
      saved = BigbluebuttonRoom.find(@room)
      saved.should have_same_attributes_as(new_room)
    }
    it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.successfully_updated')) }
    it { should assign_to(:server).with(server) }
  end

  describe "#destroy" do
    before :each do
      @room = room
      expect {
        delete :destroy, :server_id => server.to_param, :id => @room.to_param
      }.to change{ BigbluebuttonRoom.count }.by(-1)
    end
    it {
      should respond_with(:redirect)
      should redirect_to(bigbluebutton_server_rooms_path)
    }
    it { should assign_to(:server).with(server) }
  end

  describe "#join" do

    before { controller.stub_chain(:bigbluebutton_user, :name).and_return("Test name") }

    # mocking the server so we can mock the BBB API
    # we don't want to trigger real API calls here (this is done in the integration tests)
    context "mocking the server" do

      # setup basic server and API mocks
      let(:api_mock) { mock(BigBlueButton::BigBlueButtonApi) }
      let(:server_mock) { mock_model(BigbluebuttonServer) }
      before do
        server_mock.stub(:api).and_return(api_mock)
        BigbluebuttonServer.stub(:find).with(server_mock.id.to_s).and_return(server_mock)
      end

      context "if the conference is running" do
        before {
          api_mock.should_receive(:is_meeting_running?).and_return(true)
          api_mock.should_receive(:moderator_url).and_return("http://test.com/join")
        }
        before :each do
          get :join, :server_id => server_mock.to_param, :id => room.to_param
        end

        it "assigns server" do
          should assign_to(:server).with(server_mock)
        end

        it "redirects to the join url" do
          should respond_with(:redirect)
          should redirect_to("http://test.com/join")
        end
      end

      context "if the conference is NOT running" do
        before {
          api_mock.should_receive(:is_meeting_running?).and_return(false)
          api_mock.should_receive(:moderator_url).and_return("http://test.com/join")
        }

        it "creates the conference" do
          api_mock.should_receive(:create_meeting).
            with(room.meeting_name, room.meeting_id,
                 room.moderator_password, room.attendee_password,
                 room.welcome_msg)
          get :join, :server_id => server_mock.to_param, :id => room.to_param
        end
      end

    end

  end

end

