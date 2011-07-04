require 'spec_helper'
require 'bigbluebutton-api'

# Some tests mock the server and its API object
# We don't want to trigger real API calls here (this is done in the integration tests)

def build_running_json(value, error=nil)
  hash = { :running => "#{value}" }
  hash[:error] = error unless error.nil?
  hash.to_json
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
    it { should render_template(:index) }
  end

  describe "#show" do
    before(:each) { get :show, :server_id => server.to_param, :id => room.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
    it { should assign_to(:room).with(room) }
    it { should render_template(:show) }
  end

  describe "#new" do
    before(:each) { get :new, :server_id => server.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
    it { should assign_to(:room).with_kind_of(BigbluebuttonRoom) }
    it { should render_template(:new) }
  end

  describe "#edit" do
    before(:each) { get :edit, :server_id => server.to_param, :id => room.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
    it { should assign_to(:room).with(room) }
    it { should render_template(:edit) }
  end

  describe "#join_mobile" do
    let(:user) { Factory.build(:user) }
    before {
      mock_server_and_api
      controller.stub(:bigbluebutton_user) { user }
      controller.should_receive(:bigbluebutton_role).and_return(:moderator)
      mocked_api.should_receive(:join_meeting_url).
        with(room.meetingid, user.name, room.moderator_password).
        and_return("http://join_url")
    }
    before(:each) { get :join_mobile, :server_id => mocked_server.to_param, :id => room.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(mocked_server) }
    it { should assign_to(:room).with(room) }
    it { should assign_to(:join_url).with("bigbluebutton://join_url") }
    it { should render_template(:join_mobile) }
  end

  describe "#create" do
    let(:new_room) { Factory.build(:bigbluebutton_room, :server => server) }

    context "on success" do
      before :each do
        expect {
          post :create, :server_id => server.to_param, :bigbluebutton_room => new_room.attributes
        }.to change{ BigbluebuttonRoom.count }.by(1)
      end
      it {
        should respond_with(:redirect)
        should redirect_to bigbluebutton_server_room_path(server, BigbluebuttonRoom.last)
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.create.success')) }
      it { should assign_to(:server).with(server) }
      it {
        saved = BigbluebuttonRoom.last
        saved.should have_same_attributes_as(new_room)
      }
    end

    context "on failure" do
      before :each do
        new_room.name = nil # invalid
        expect {
          post :create, :server_id => server.to_param, :bigbluebutton_room => new_room.attributes
        }.not_to change{ BigbluebuttonRoom.count }
      end
      it { should render_template(:new) }
      it { should assign_to(:server).with(server) }
    end

    context "with :redir_url" do
      it "on success" do
        expect {
          post :create, :server_id => server.to_param, :bigbluebutton_room => new_room.attributes,
                        :redir_url => bigbluebutton_servers_path
        }.to change{ BigbluebuttonRoom.count }.by(1)
        should respond_with(:redirect)
        should redirect_to bigbluebutton_servers_path
      end
      it "on failure" do
        new_room.name = nil # invalid
        expect {
          post :create, :server_id => server.to_param, :bigbluebutton_room => new_room.attributes,
                        :redir_url => bigbluebutton_servers_path
        }.not_to change{ BigbluebuttonRoom.count }
        should respond_with(:redirect)
        should redirect_to bigbluebutton_servers_path
      end
    end

    context "when meetingid is not specified it should be copied from name" do
      before :each do
        attr = new_room.attributes
        attr.delete("meetingid")
        post :create, :server_id => server.to_param, :bigbluebutton_room => attr
      end
      it {
        saved = BigbluebuttonRoom.last
        new_room.meetingid = new_room.name
        saved.should have_same_attributes_as(new_room)
      }
    end
  end

  describe "#update" do
    let(:new_room) { Factory.build(:bigbluebutton_room) }
    before { @room = room } # need this to trigger let(:room) and actually create the room

    context "on success" do
      before :each do
        expect {
          put :update, :server_id => server.to_param, :id => @room.to_param, :bigbluebutton_room => new_room.attributes
        }.not_to change{ BigbluebuttonRoom.count }
      end
      it {
        saved = BigbluebuttonRoom.find(@room)
        should respond_with(:redirect)
        should redirect_to bigbluebutton_server_room_path(server, saved)
      }
      it {
        saved = BigbluebuttonRoom.find(@room)
        saved.should have_same_attributes_as(new_room)
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.update.success')) }
      it { should assign_to(:server).with(server) }
    end

    context "on failure" do
      before :each do
        new_room.name = nil # invalid
        put :update, :server_id => server.to_param, :id => @room.to_param, :bigbluebutton_room => new_room.attributes
      end
      it { should render_template(:edit) }
      it { should assign_to(:server).with(server) }
      it { should assign_to(:room).with(@room) }
    end

    context "with :redir_url" do
      it "on success" do
        put :update, :server_id => server.to_param, :id => @room.to_param, :bigbluebutton_room => new_room.attributes,
                     :redir_url => bigbluebutton_servers_path
        should respond_with(:redirect)
        should redirect_to bigbluebutton_servers_path
      end
      it "on failure" do
        new_room.name = nil # invalid
        put :update, :server_id => server.to_param, :id => @room.to_param, :bigbluebutton_room => new_room.attributes,
                     :redir_url => bigbluebutton_servers_path
        should respond_with(:redirect)
        should redirect_to bigbluebutton_servers_path
      end
    end

    context "when meetingid is not specified should copied from name" do
      before :each do
        attr = new_room.attributes
        attr.delete("meetingid")
        put :update, :server_id => server.to_param, :id => @room.to_param, :bigbluebutton_room => attr
      end
      it {
        saved = BigbluebuttonRoom.find(@room)
        new_room.meetingid = new_room.name
        saved.should have_same_attributes_as(new_room)
      }
    end

  end

  describe "#destroy" do
    before {
      mock_server_and_api
      # to make sure it calls end_meeting if the meeting is running
      mocked_api.should_receive(:is_meeting_running?).and_return(true)
      mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_password)
    }

    context do
      before :each do
        expect {
          delete :destroy, :server_id => mocked_server.to_param, :id => room.to_param
        }.to change{ BigbluebuttonRoom.count }.by(-1)
      end
      it {
        should respond_with(:redirect)
        should redirect_to bigbluebutton_server_rooms_url
      }
      it { should assign_to(:server).with(mocked_server) }
    end

    it "with :redir_url" do
      expect {
        delete :destroy, :server_id => mocked_server.to_param, :id => room.to_param,
                         :redir_url => bigbluebutton_servers_path
      }.to change{ BigbluebuttonRoom.count }.by(-1)
      should respond_with(:redirect)
      should redirect_to bigbluebutton_servers_path
    end

  end

  describe "#running" do
    # setup basic server and API mocks
    before { mock_server_and_api }

    context "room is running" do
      before { mocked_api.should_receive(:is_meeting_running?).and_return(true) }
      before(:each) { get :running, :server_id => mocked_server.to_param, :id => room.to_param }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should assign_to(:server).with(mocked_server) }
      it { should assign_to(:room).with(room) }
      it { response.body.should == build_running_json(true) }
    end

    context "room is not running" do
      before { mocked_api.should_receive(:is_meeting_running?).and_return(false) }
      before(:each) { get :running, :server_id => mocked_server.to_param, :id => room.to_param }
      it { response.body.should == build_running_json(false) }
    end
  end

  describe "#join" do
    let(:user) { Factory.build(:user) }
    before { mock_server_and_api }

    context "for an anonymous user" do
      before { controller.stub(:bigbluebutton_user) { nil } }
      before { controller.stub(:bigbluebutton_role) { :moderator } }
      before(:each) { get :join, :server_id => mocked_server.to_param, :id => room.to_param }
      it {
        should respond_with(:redirect)
        should redirect_to(invite_bigbluebutton_server_room_path(mocked_server, room))
      }
    end

    context "when the user's role" do
      before { controller.stub(:bigbluebutton_user) { user } }

      context "should be defined with a password" do
        before { controller.stub(:bigbluebutton_role) { :password } }
        before(:each) { get :join, :server_id => mocked_server.to_param, :id => room.to_param }
        it { should respond_with(:redirect) }
        it { should redirect_to(invite_bigbluebutton_server_room_path(mocked_server, room)) }
      end

      context "is undefined, the access should be blocked" do
        before { controller.stub(:bigbluebutton_role) { nil } }
        it {
          lambda {
            get :join, :server_id => mocked_server.to_param, :id => room.to_param
          }.should raise_error(BigbluebuttonRails::RoomAccessDenied)
        }
      end
    end

    # verify the behaviour of .join_internal
    # see support/shared_examples/rooms_controller.rb
    context "calling .join_internal" do
      let(:request) { get :join, :server_id => mocked_server.to_param, :id => room.to_param }
      let(:template) { :join }
      before { controller.stub(:bigbluebutton_user) { user } }

      context "as moderator:" do
        before { controller.should_receive(:bigbluebutton_role).with(room).and_return(:moderator) }
        it_should_behave_like "internal join caller (moderator)"
      end

      context "as attendee:" do
        before { controller.should_receive(:bigbluebutton_role).with(room).and_return(:attendee) }
        it_should_behave_like "internal join caller (attendee)"
      end
    end

  end

  describe "#end" do
    before { mock_server_and_api }

    context "room is running" do
      before {
        mocked_api.should_receive(:is_meeting_running?).and_return(true)
        mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_password)
      }
      before(:each) { get :end, :server_id => mocked_server.to_param, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to(bigbluebutton_server_room_path(mocked_server, room)) }
      it { should assign_to(:server).with(mocked_server) }
      it { should assign_to(:room).with(room) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.end.success')) }
    end

    context "room is not running" do
      before { mocked_api.should_receive(:is_meeting_running?).and_return(false) }
      before(:each) { get :end, :server_id => mocked_server.to_param, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.end.not_running')) }
    end
  end

  describe "#invite" do
    before { mock_server_and_api }
    let(:user) { Factory.build(:user) }

    context "for an anonymous user" do
      before { controller.stub(:bigbluebutton_user).and_return(nil) }

      context "with a role defined" do
        before { controller.stub(:bigbluebutton_role).and_return(:attendee) }
        before(:each) { get :invite, :server_id => mocked_server.to_param, :id => room.to_param }
        it { should respond_with(:success) }
        it { should render_template(:invite) }
        it { should assign_to(:room).with(room) }
      end

      context "when the user's role" do
        context "should be defined with a password" do
          before { controller.stub(:bigbluebutton_role) { :password } }
          before(:each) { get :invite, :server_id => mocked_server.to_param, :id => room.to_param }
          it { should respond_with(:success) }
          it { should render_template(:invite) }
          it { should assign_to(:room).with(room) }
        end

        context "is undefined, the access should be blocked" do
          before { controller.stub(:bigbluebutton_role) { nil } }
          it {
            lambda {
              get :invite, :server_id => mocked_server.to_param, :id => room.to_param
            }.should raise_error(BigbluebuttonRails::RoomAccessDenied)
          }
        end
      end
    end

    context "for a logged user" do
      before { controller.stub(:bigbluebutton_user).and_return(user) }

      context "with a role defined" do
        before { controller.stub(:bigbluebutton_role).and_return(:attendee) }
        before(:each) { get :invite, :server_id => mocked_server.to_param, :id => room.to_param }
        it { should respond_with(:redirect) }
        it { should redirect_to(join_bigbluebutton_server_room_path(mocked_server, room)) }
      end

      context "when the user's role" do
        context "should be defined with a password" do
          before { controller.stub(:bigbluebutton_role) { :password } }
          before(:each) { get :invite, :server_id => mocked_server.to_param, :id => room.to_param }
          it { should respond_with(:success) }
          it { should render_template(:invite) }
          it { should assign_to(:room).with(room) }
        end

        context "is undefined, the access should be blocked" do
          before { controller.stub(:bigbluebutton_role) { nil } }
          it {
            lambda {
              get :invite, :server_id => mocked_server.to_param, :id => room.to_param
            }.should raise_error(BigbluebuttonRails::RoomAccessDenied)
          }
        end
      end
    end

  end

  describe "#auth" do
    let(:user) { Factory.build(:user) }
    before {
      mock_server_and_api
      controller.stub(:bigbluebutton_user).and_return(nil)
    }

    context "assigns @room" do
      let(:user_hash) { { :name => "Elftor", :password => room.attendee_password } }
      let(:meetingid) { "my-meeting-id" }
      let(:http_referer) { bigbluebutton_server_path(mocked_server) }
      before {
        mocked_api.stub!(:is_meeting_running?)
        request.env["HTTP_REFERER"] = http_referer
      }

      context "if params[:id]" do
        before(:each) { post :auth, :server_id => mocked_server.to_param, :id => room.to_param, :user => user_hash }
        it { should assign_to(:room).with(room) }
      end

      context "if params[:id] doesn't exists" do
        let(:message) { I18n.t('bigbluebutton_rails.rooms.errors.auth.wrong_params') }
        before(:each) { post :auth, :server_id => mocked_server.to_param, :id => "inexistent-room-id", :user => user_hash }
        it { should assign_to(:room).with(nil) }
        it { should respond_with(:redirect) }
        it { should redirect_to(http_referer) }
        it { should set_the_flash.to(message) }
      end
    end

    context "block access if bigbluebutton_role returns nil" do
      let(:hash) { { :name => "Elftor", :password => room.attendee_password } }
      before { controller.stub(:bigbluebutton_role) { nil } }
      it {
        lambda {
          post :auth, :server_id => mocked_server.to_param, :id => room.to_param, :user => hash
        }.should raise_error(BigbluebuttonRails::RoomAccessDenied)
      }
    end

    context "if there's a user logged, should use his name" do
      let(:hash) { { :name => "Elftor", :password => room.attendee_password } }
      it do
        controller.stub(:bigbluebutton_user).and_return(user)
        mocked_api.should_receive(:is_meeting_running?).and_return(true)
        mocked_api.should_receive(:join_meeting_url).
          with(room.meetingid, user.name, room.attendee_password).
          and_return("http://test.com/attendee/join")
        post :auth, :server_id => mocked_server.to_param, :id => room.to_param, :user => hash
        should respond_with(:redirect)
        should redirect_to("http://test.com/attendee/join")
      end
    end

    pending "redirects to the correct join_url"

    context "validates user input and shows error" do
      before(:each) { post :auth, :server_id => mocked_server.to_param, :id => room.to_param, :user => user_hash }

      context "when name is not set" do
        let(:user_hash) { { :password => room.moderator_password } }
        it { should respond_with(:unauthorized) }
        it { should assign_to(:room).with(room) }
        it { should render_template(:invite) }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.failure')) }
      end

      context "when the password is wrong" do
        let(:user_hash) { { :name => "Elftor", :password => nil } }
        it { should respond_with(:unauthorized) }
        it { should assign_to(:room).with(room) }
        it { should render_template(:invite) }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.failure')) }
      end
    end

    # verify the behaviour of .join_internal
    # see support/shared_examples/rooms_controller.rb
    context "calling .join_internal" do
      # set the variables for the shared example
      let(:template) { :invite }
      let(:request) { post :auth, :server_id => mocked_server.to_param, :id => room.to_param, :user => hash }

      context "as moderator:" do
        let(:hash) { { :name => "Elftor", :password => room.moderator_password } }
        it_should_behave_like "internal join caller (moderator)"
      end

      context "as attendee:" do
        let(:hash) { { :name => "Elftor", :password => room.attendee_password } }
        it_should_behave_like "internal join caller (attendee)"
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

  # make sure that the exceptions thrown by bigbluebutton-api-ruby are treated by the controller
  context "exception handling" do
    let(:bbb_error_msg) { "err msg" }
    let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
    let(:http_referer) { bigbluebutton_server_path(mocked_server) }
    before {
      mock_server_and_api
      request.env["HTTP_REFERER"] = http_referer
    }

    describe "#destroy" do
      it "catches exception on is_meeting_running" do
        mocked_api.should_receive(:is_meeting_running?) { raise bbb_error }
      end

      it "catches exception on end_meeting" do
        mocked_api.should_receive(:is_meeting_running?).and_return(true)
        mocked_api.should_receive(:end_meeting) { raise bbb_error }
      end

      after :each do
        delete :destroy, :server_id => mocked_server.to_param, :id => room.to_param
        should respond_with(:redirect)
        should redirect_to bigbluebutton_server_rooms_url
        should set_the_flash.to(bbb_error_msg)
      end
    end

    describe "#running" do
      before { mocked_api.should_receive(:is_meeting_running?) { raise bbb_error } }
      before(:each) { get :running, :server_id => mocked_server.to_param, :id => room.to_param }
      it { should respond_with(:success) }
      it { response.body.should == build_running_json(false, bbb_error_msg) }
      it { should set_the_flash.to(bbb_error_msg) }
    end

    describe "#end" do
      it "catches exception on is_meeting_running" do
        mocked_api.should_receive(:is_meeting_running?) { raise bbb_error }
      end

      it "catches exception on end_meeting" do
        mocked_api.should_receive(:is_meeting_running?).and_return(true)
        mocked_api.should_receive(:end_meeting) { raise bbb_error }
      end

      after :each do
        get :end, :server_id => mocked_server.to_param, :id => room.to_param
        should respond_with(:redirect)
        should redirect_to(http_referer)
        should set_the_flash.to(bbb_error_msg)
      end
    end

    describe "#join" do
      before { controller.stub(:bigbluebutton_user) { Factory.build(:user) } }

      context "as moderator" do
        before { controller.should_receive(:bigbluebutton_role).with(room).and_return(:moderator) }

        it "catches exception on is_meeting_running" do
          mocked_api.should_receive(:is_meeting_running?) { raise bbb_error }
        end

        it "catches exception on create_meeting" do
          mocked_api.should_receive(:is_meeting_running?).and_return(false)
          mocked_api.should_receive(:create_meeting) { raise bbb_error }
        end

        it "catches exception on join_meeting_url" do
          mocked_api.should_receive(:is_meeting_running?).and_return(true)
          mocked_api.should_receive(:join_meeting_url) { raise bbb_error }
        end

        after :each do
          get :join, :server_id => mocked_server.to_param, :id => room.to_param
          should respond_with(:redirect)
          should redirect_to(http_referer)
          should set_the_flash.to(bbb_error_msg)
        end

      end

      context "as moderator" do
        before { controller.should_receive(:bigbluebutton_role).with(room).and_return(:attendee) }

        it "catches exception on is_meeting_running" do
          mocked_api.should_receive(:is_meeting_running?) { raise bbb_error }
        end

        it "catches exception on join_meeting_url" do
          mocked_api.should_receive(:is_meeting_running?).and_return(true)
          mocked_api.should_receive(:join_meeting_url) { raise bbb_error }
        end

        after :each do
          get :join, :server_id => mocked_server.to_param, :id => room.to_param
          should respond_with(:redirect)
          should redirect_to(http_referer)
          should set_the_flash.to(bbb_error_msg)
        end
      end

    end # #join

  end # exception handling

  # verify all JSON responses
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

  end # json responses

  describe "#external" do
    before { mock_server_and_api }
    let(:new_room) { BigbluebuttonRoom.new(:meetingid => 'my-meeting-id') }

    context "on success" do
      before { controller.stub(:bigbluebutton_user).and_return(nil) }
      before(:each) { get :external, :server_id => mocked_server.to_param, :meeting => new_room.meetingid }
      it { should assign_to(:server).with(mocked_server) }
      it { should respond_with(:success) }
      it { should render_template(:external) }
      it { should assign_to(:room).with_kind_of(BigbluebuttonRoom) }
      it { assigns(:room).meetingid.should be(new_room.meetingid) }
    end

    context "when params[:meeting].blank?" do
      before { controller.stub(:bigbluebutton_user).and_return(nil) }

      context "without params[:redir_url]" do
        before(:each) { get :external, :server_id => mocked_server.to_param }
        it { should respond_with(:redirect) }
        it { should redirect_to bigbluebutton_server_rooms_path(mocked_server) }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.external.blank_meetingid')) }
      end

      context "with params[:redir_url]" do
        before(:each) { get :external, :server_id => mocked_server.to_param, :redir_url => '/'}
        it { should redirect_to '/' }
      end
    end
  end # #external

  describe "#external_auth" do
    let(:user) { Factory.build(:user) }
    let(:meetingid) { "my-meeting-id" }
    let(:new_room) { BigbluebuttonRoom.new(:meetingid => meetingid,
                                           :attendee_password => Forgery(:basic).password,
                                           :moderator_password => Forgery(:basic).password,
                                           :server => mocked_server) }
    let(:meetings) { [ new_room ] }
    let(:http_referer) { bigbluebutton_server_path(mocked_server) }
    before {
      mock_server_and_api
      controller.stub(:bigbluebutton_user).and_return(nil)
      request.env["HTTP_REFERER"] = http_referer
    }

    context "assigns @room" do
      let(:user_hash) { { :name => "Elftor", :password => new_room.attendee_password } }

      context "if params[:meeting] and params[:user]" do
        before { # TODO: this block is being repeated several times, put it in a method or something
          mocked_server.should_receive(:fetch_meetings)
          mocked_server.should_receive(:meetings).and_return(meetings)
          new_room.should_receive(:fetch_meeting_info)
        }
        before(:each) { post :external_auth, :server_id => mocked_server.to_param, :meeting => new_room.meetingid, :user => user_hash }
        it { should assign_to(:room).with(new_room) }
      end

      context "if not params[:meeting]" do
        let(:message) { I18n.t('bigbluebutton_rails.rooms.errors.auth.wrong_params') }
        before(:each) { post :external_auth, :server_id => mocked_server.to_param, :meeting => nil, :user => user_hash }
        it { should assign_to(:room).with(nil) }
        it { should respond_with(:redirect) }
        it { should redirect_to(http_referer) }
        it { should set_the_flash.to(message) }
      end

      context "if not params[:user]" do
        let(:message) { I18n.t('bigbluebutton_rails.rooms.errors.auth.wrong_params') }
        before(:each) { post :external_auth, :server_id => mocked_server.to_param, :meeting => new_room.meetingid, :user => nil }
        it { should assign_to(:room).with(nil) }
        it { should respond_with(:redirect) }
        it { should redirect_to(http_referer) }
        it { should set_the_flash.to(message) }
      end
    end

    context "block access if bigbluebutton_role returns nil" do
      let(:user_hash) { { :name => "Elftor", :password => new_room.attendee_password } }
      before {
        mocked_server.should_receive(:fetch_meetings)
        mocked_server.should_receive(:meetings).and_return(meetings)
        controller.stub(:bigbluebutton_role) { nil }
      }
      it {
        lambda {
          post :external_auth, :server_id => mocked_server.to_param, :meeting => new_room.meetingid, :user => user_hash
        }.should raise_error(BigbluebuttonRails::RoomAccessDenied)
      }
    end

    context "fetches meeting info" do
      let(:user_hash) { { :name => "Elftor", :password => new_room.attendee_password } }
      before {
        mocked_server.should_receive(:fetch_meetings)
        mocked_server.should_receive(:meetings).and_return(meetings)
      }
      it do
        new_room.should_receive(:fetch_meeting_info)
        post :external_auth, :server_id => mocked_server.to_param, :meeting => new_room.meetingid, :user => user_hash
      end
    end

    context "if there's a user logged, should use his name" do
      let(:user) { Factory.build(:user) }
      let(:user_hash) { { :name => "Elftor", :password => new_room.attendee_password } }
      before {
        mocked_server.should_receive(:fetch_meetings)
        mocked_server.should_receive(:meetings).and_return(meetings)
        new_room.should_receive(:fetch_meeting_info)
        new_room.running = true
      }
      it do
        controller.stub(:bigbluebutton_user).and_return(user)
        mocked_api.should_receive(:join_meeting_url).
          with(new_room.meetingid, user.name, new_room.attendee_password).
          and_return("http://test.com/attendee/join")
        post :external_auth, :server_id => mocked_server.to_param, :meeting => new_room.meetingid, :user => user_hash
      end
    end

    context "validates user input and shows error" do
      before {
        mocked_server.should_receive(:fetch_meetings)
        mocked_server.should_receive(:meetings).and_return(meetings)
      }
      before(:each) { post :external_auth, :server_id => mocked_server.to_param, :meeting => new_room.meetingid, :user => user_hash }

      context "when name is not set" do
        let(:user_hash) { { :password => room.moderator_password } }
        it { should respond_with(:unauthorized) }
        it { should assign_to(:room).with(new_room) }
        it { should render_template(:external) }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.failure')) }
      end

      context "when the password is wrong" do
        let(:user_hash) { { :name => "Elftor", :password => nil } }
        it { should respond_with(:unauthorized) }
        it { should assign_to(:room).with(new_room) }
        it { should render_template(:external) }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.failure')) }
      end

      pending "redirects to the correct join_url"
      pending "joins if the meeting is running"
      pending "if the meeting is not running shows error"

    end

  end # #external_auth

end

