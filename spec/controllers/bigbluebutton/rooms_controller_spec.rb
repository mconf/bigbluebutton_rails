require 'spec_helper'
require 'bigbluebutton-api'

def build_running_json(value)
  { :running => "#{value}" }.to_json
end

def mock_server_and_api
  @api_mock = mock(BigBlueButton::BigBlueButtonApi)
  @server_mock = mock_model(BigbluebuttonServer)
  @server_mock.stub(:api).and_return(@api_mock)
  BigbluebuttonServer.stub(:find).with(@server_mock.id.to_s).and_return(@server_mock)
end

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

  describe "#running" do
    # setup basic server and API mocks
    before { mock_server_and_api }

    context "room is running" do
      before { @api_mock.should_receive(:is_meeting_running?).and_return(true) }
      before(:each) { get :running, :server_id => @server_mock.to_param, :id => room.to_param }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should assign_to(:server).with(@server_mock) }
      it { should assign_to(:room).with(room) }
      it { response.body.should == build_running_json(true) }
    end

    context "room is not running" do
      before { @api_mock.should_receive(:is_meeting_running?).and_return(false) }
      before(:each) { get :running, :server_id => @server_mock.to_param, :id => room.to_param }
      it { response.body.should == build_running_json(false) }
    end
  end

  describe "#join" do

    before { controller.stub_chain(:bigbluebutton_user, :name).and_return("Test name") }

    # mock the server so we can mock the BBB API
    # we don't want to trigger real API calls here (this is done in the integration tests)

    # setup basic server and API mocks
    before { mock_server_and_api }

    context "if the user is a moderator" do
      before {
        controller.should_receive(:bigbluebutton_role).with(room).and_return(:moderator)
        @api_mock.should_receive(:moderator_url).and_return("http://test.com/mod/join")
      }

      context "and the conference is running" do
        before {
          @api_mock.should_receive(:is_meeting_running?).and_return(true)
        }

        it "assigns server" do
          get :join, :server_id => @server_mock.to_param, :id => room.to_param
          should assign_to(:server).with(@server_mock)
        end

        it "redirects to the moderator join url" do
          get :join, :server_id => @server_mock.to_param, :id => room.to_param
          should respond_with(:redirect)
          should redirect_to("http://test.com/mod/join")
        end
      end

      context "and the conference is NOT running" do
        before {
          @api_mock.should_receive(:is_meeting_running?).and_return(false)
        }

        it "creates the conference" do
          @api_mock.should_receive(:create_meeting).
            with(room.meeting_name, room.meeting_id, room.moderator_password,
                 room.attendee_password, room.welcome_msg)
          get :join, :server_id => @server_mock.to_param, :id => room.to_param
        end
      end

    end

    context "if the user is an attendee" do
      before {
        controller.should_receive(:bigbluebutton_role).with(room).and_return(:attendee)
      }

      context "and the conference is running" do
        before {
          @api_mock.should_receive(:is_meeting_running?).and_return(true)
          @api_mock.should_receive(:attendee_url).and_return("http://test.com/attendee/join")
        }

        it "assigns server" do
          get :join, :server_id => @server_mock.to_param, :id => room.to_param
          should assign_to(:server).with(@server_mock)
        end

        it "redirects to the attendee join url" do
          get :join, :server_id => @server_mock.to_param, :id => room.to_param
          should respond_with(:redirect)
          should redirect_to("http://test.com/attendee/join")
        end
      end

      context "and the conference is NOT running" do
        before {
          @api_mock.should_receive(:is_meeting_running?).and_return(false)
        }

        it "do not try to create the conference" do
          @api_mock.should_not_receive(:create_meeting)
          get :join, :server_id => @server_mock.to_param, :id => room.to_param
        end

        it "render the join_wait view to wait for a moderator" do
          get :join, :server_id => @server_mock.to_param, :id => room.to_param
          should respond_with(:success)
          should render_template(:join_wait)
        end
      end

    end

  end

  # can be used when matching rooms inside some resource other than servers
  context "selects the first server when the server_id in the url is inexistent" do
    let(:server2) { Factory.create(:bigbluebutton_server) }
    
    # get /users/:user_id/room/:id(.:format)
    before(:each) { get :show, :id => room.to_param, :user_id => "1" }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
  end

end

