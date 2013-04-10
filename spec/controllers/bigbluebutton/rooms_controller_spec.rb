require 'spec_helper'
require 'bigbluebutton_api'

# Some tests mock the server and its API object
# We don't want to trigger real API calls here (this is done in the integration tests)

describe Bigbluebutton::RoomsController do
  render_views
  let(:server) { FactoryGirl.create(:bigbluebutton_server) }
  let(:room) { FactoryGirl.create(:bigbluebutton_room, :server => server) }

  describe "#index" do
    before { 3.times { FactoryGirl.create(:bigbluebutton_room) } }
    before(:each) { get :index }
    it { should respond_with(:success) }
    it { should assign_to(:rooms).with(BigbluebuttonRoom.all) }
    it { should render_template(:index) }
  end

  describe "#show" do
    before(:each) { get :show, :id => room.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:room).with(room) }
    it { should render_template(:show) }
  end

  describe "#new" do
    before(:each) { get :new }
    it { should respond_with(:success) }
    it { should assign_to(:room).with_kind_of(BigbluebuttonRoom) }
    it { should render_template(:new) }
  end

  describe "#edit" do
    before(:each) { get :edit, :id => room.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:room).with(room) }
    it { should render_template(:edit) }
  end

  describe "#join_mobile" do
    let(:user) { FactoryGirl.build(:user) }
    let(:room) { FactoryGirl.create(:bigbluebutton_room) }
    before {
      controller.should_receive(:set_request_headers)
      mock_server_and_api
      room.server = mocked_server
      controller.stub(:bigbluebutton_user) { user }
      controller.should_receive(:bigbluebutton_role).and_return(:moderator)
      controller.should_receive(:join_bigbluebutton_room_url).with(room, :mobile => '1').
        and_return("http://test.com/join/url?mobile=1")
      mocked_api.should_receive(:join_meeting_url).with(room.meetingid, user.name, room.moderator_password).
        and_return("bigbluebutton://test.com/open/url/for/qrcode")
    }
    before(:each) { get :join_mobile, :id => room.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:room).with(room) }
    it { should assign_to(:join_url).with("bigbluebutton://test.com/join/url?mobile=1") }
    it { should assign_to(:qrcode_url).with("bigbluebutton://test.com/open/url/for/qrcode") }
    it { should render_template(:join_mobile) }
  end

  describe "#create" do
    let(:new_room) { FactoryGirl.build(:bigbluebutton_room, :server => server) }

    context "on success" do
      before :each do
        expect {
          post :create, :bigbluebutton_room => new_room.attributes
        }.to change{ BigbluebuttonRoom.count }.by(1)
      end
      it {
        should respond_with(:redirect)
        should redirect_to bigbluebutton_room_path(BigbluebuttonRoom.last)
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.create.success')) }
      it {
        saved = BigbluebuttonRoom.last
        saved.should have_same_attributes_as(new_room)
      }
    end

    context "on failure" do
      before :each do
        new_room.name = nil # invalid
        expect {
          post :create, :bigbluebutton_room => new_room.attributes
        }.not_to change{ BigbluebuttonRoom.count }
      end
      it { should render_template(:new) }
    end

    context "with :redir_url" do
      it "on success" do
        expect {
          post :create, :bigbluebutton_room => new_room.attributes, :redir_url => bigbluebutton_servers_path
        }.to change{ BigbluebuttonRoom.count }.by(1)
        should respond_with(:redirect)
        should redirect_to bigbluebutton_servers_path
      end
      it "on failure" do
        new_room.name = nil # invalid
        expect {
          post :create, :bigbluebutton_room => new_room.attributes, :redir_url => bigbluebutton_servers_path
        }.not_to change{ BigbluebuttonRoom.count }
        should respond_with(:redirect)
        should redirect_to bigbluebutton_servers_path
      end
    end

    context "when meetingid is not specified it should be copied from name" do
      before :each do
        attr = new_room.attributes
        attr.delete("meetingid")
        post :create, :bigbluebutton_room => attr
      end
      it {
        saved = BigbluebuttonRoom.last
        new_room.meetingid = new_room.name
        saved.should have_same_attributes_as(new_room)
      }
    end
  end

  describe "#update" do
    let(:new_room) { FactoryGirl.build(:bigbluebutton_room) }
    before { @room = room } # need this to trigger let(:room) and actually create the room

    context "on success" do
      before :each do
        expect {
          put :update, :id => @room.to_param, :bigbluebutton_room => new_room.attributes
        }.not_to change{ BigbluebuttonRoom.count }
      end
      it {
        saved = BigbluebuttonRoom.find(@room)
        should respond_with(:redirect)
        should redirect_to bigbluebutton_room_path(saved)
      }
      it {
        saved = BigbluebuttonRoom.find(@room)
        saved.should have_same_attributes_as(new_room)
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.update.success')) }
    end

    context "on failure" do
      before :each do
        new_room.name = nil # invalid
        put :update, :id => @room.to_param, :bigbluebutton_room => new_room.attributes
      end
      it { should render_template(:edit) }
      it { should assign_to(:room).with(@room) }
    end

    context "with :redir_url" do
      it "on success" do
        put :update, :id => @room.to_param, :bigbluebutton_room => new_room.attributes,
                     :redir_url => bigbluebutton_servers_path
        should respond_with(:redirect)
        should redirect_to bigbluebutton_servers_path
      end
      it "on failure" do
        new_room.name = nil # invalid
        put :update, :id => @room.to_param, :bigbluebutton_room => new_room.attributes,
                     :redir_url => bigbluebutton_servers_path
        should respond_with(:redirect)
        should redirect_to bigbluebutton_servers_path
      end
    end

  end

  describe "#destroy" do
    before {
      controller.should_receive(:set_request_headers)
      mock_server_and_api
      # to make sure it calls end_meeting if the meeting is running
      mocked_api.should_receive(:is_meeting_running?).and_return(true)
    }

    context "on success" do
      before(:each) {
        mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_password)
        expect {
          delete :destroy, :id => room.to_param
        }.to change{ BigbluebuttonRoom.count }.by(-1)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_rooms_url }
    end

    context "on failure" do
      let(:bbb_error_msg) { SecureRandom.hex(250) }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
      before {
        mocked_api.should_receive(:end_meeting) { raise bbb_error }
      }
      before(:each) {
        expect {
          delete :destroy, :id => room.to_param
        }.to change{ BigbluebuttonRoom.count }.by(-1)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_rooms_url }
      it {
        msg = I18n.t('bigbluebutton_rails.rooms.notice.destroy.success_with_bbb_error', :error => bbb_error_msg[0..200])
        should set_the_flash.to(msg)
      }
    end

    context "with :redir_url" do
      before(:each) {
        expect {
          mocked_api.should_receive(:end_meeting)
          delete :destroy, :id => room.to_param, :redir_url => bigbluebutton_servers_path
        }.to change{ BigbluebuttonRoom.count }.by(-1)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_servers_path }
    end

  end

  describe "#running" do
    # setup basic server and API mocks
    before {
      controller.should_receive(:set_request_headers)
      mock_server_and_api
    }

    context "room is running" do
      before { @api_mock.should_receive(:is_meeting_running?).and_return(true) }
      before(:each) { get :running, :id => room.to_param }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should assign_to(:room).with(room) }
      it { response.body.should == build_running_json(true) }
    end

    context "room is not running" do
      before { mocked_api.should_receive(:is_meeting_running?).and_return(false) }
      before(:each) { get :running, :id => room.to_param }
      it { response.body.should == build_running_json(false) }
    end

    context "on failure" do
      let(:bbb_error_msg) { SecureRandom.hex(250) }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
      before { mocked_api.should_receive(:is_meeting_running?)  { raise bbb_error } }
      before(:each) { get :running, :id => room.to_param }
      it { should respond_with(:success) }
      it { should set_the_flash.to(bbb_error_msg[0..200]) }
    end
  end

  describe "#join" do
    let(:user) { FactoryGirl.build(:user) }
    before {
      controller.should_receive(:set_request_headers)
      mock_server_and_api
    }

    context "for an anonymous user" do
      before { controller.stub(:bigbluebutton_user) { nil } }
      before { controller.stub(:bigbluebutton_role) { :password } }
      before(:each) { get :join, :id => room.to_param }
      it { should assign_to(:user_role).with(:password) }
      it { should respond_with(:redirect) }
      it { should redirect_to(invite_bigbluebutton_room_path(room)) }
    end

    context "when the user's role" do
      before { controller.stub(:bigbluebutton_user) { user } }

      context "should be defined with a password" do
        before { controller.stub(:bigbluebutton_role) { :password } }
        before(:each) { get :join, :id => room.to_param }
        it { should respond_with(:redirect) }
        it { should assign_to(:user_role).with(:password) }
        it { should redirect_to(invite_bigbluebutton_room_path(room)) }
      end

      context "is undefined, the access should be blocked" do
        before { controller.stub(:bigbluebutton_role) { nil } }
        it {
          lambda {
            get :join, :id => room.to_param
          }.should raise_error(BigbluebuttonRails::RoomAccessDenied)
        }
      end
    end

    context "calls #join_internal" do
      before {
        controller.stub(:bigbluebutton_user) { user }
        controller.stub(:bigbluebutton_role) { :moderator }
        controller.should_receive(:join_internal)
          .with(user.name, :moderator, user.id, :join)
      }
      it { get :join, :id => room.to_param }
    end
  end

  describe "#end" do
    before {
      controller.should_receive(:set_request_headers)
      mock_server_and_api
      request.env["HTTP_REFERER"] = "/any"
    }

    context "room is running" do
      before {
        mocked_api.should_receive(:is_meeting_running?).and_return(true)
        mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_password)
      }
      before(:each) { get :end, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to(bigbluebutton_room_path(room)) }
      it { should assign_to(:room).with(room) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.end.success')) }
    end

    context "room is not running" do
      before {
        mocked_api.should_receive(:is_meeting_running?).and_return(false)
      }
      before(:each) { get :end, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.end.not_running')) }
      it { should redirect_to("/any") }
    end

    context "on failure" do
      let(:bbb_error_msg) { SecureRandom.hex(250) }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
      before { mocked_api.should_receive(:is_meeting_running?) { raise bbb_error } }
      before(:each) { get :end, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should set_the_flash.to(bbb_error_msg[0..200]) }
    end
  end

  describe "#invite" do
    before { mock_server_and_api }
    let(:user) { FactoryGirl.build(:user) }
    before { controller.stub(:bigbluebutton_user).and_return(user) }

    context "when the user has a role defined" do
      before { controller.stub(:bigbluebutton_role).and_return(:attendee) }
      before(:each) { get :invite, :id => room.to_param }
      it { should respond_with(:success) }
      it { should render_template(:invite) }
      it { should assign_to(:room).with(room) }
      it { should assign_to(:user_role).with(:attendee) }
    end

    context "when the user's role" do
      context "should be defined with a password" do
        before { controller.stub(:bigbluebutton_role) { :password } }
        before(:each) { get :invite, :id => room.to_param }
        it { should respond_with(:success) }
        it { should render_template(:invite) }
        it { should assign_to(:room).with(room) }
        it { should assign_to(:user_role).with(:password) }
      end

      context "is undefined, the access should be blocked" do
        before { controller.stub(:bigbluebutton_role) { nil } }
        it {
          lambda {
            get :invite, :id => room.to_param
          }.should raise_error(BigbluebuttonRails::RoomAccessDenied)
        }
      end
    end
  end

  describe "#auth" do
    let(:user) { FactoryGirl.build(:user) }
    before {
      controller.should_receive(:set_request_headers)
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
        before(:each) { post :auth, :id => room.to_param, :user => user_hash }
        it { should assign_to(:room).with(room) }
      end

      context "if params[:id] doesn't exists" do
        let(:message) { I18n.t('bigbluebutton_rails.rooms.errors.auth.wrong_params') }
        before(:each) {
          BigbluebuttonRoom.should_receive(:find_by_param)
                           .with("inexistent-room-id") { nil }
          post :auth, :id => "inexistent-room-id", :user => user_hash
        }
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
          post :auth, :id => room.to_param, :user => hash
        }.should raise_error(BigbluebuttonRails::RoomAccessDenied)
      }
    end

    it "if there's a user logged, should use his name" do
      controller.stub(:bigbluebutton_role) { :password }
      hash = { :name => "Elftor", :password => room.attendee_password }
      controller.stub(:bigbluebutton_user).and_return(user)
      mocked_api.should_receive(:is_meeting_running?).and_return(true)
      mocked_api.should_receive(:join_meeting_url).
        with(room.meetingid, user.name, room.attendee_password). # here's the validation
        and_return("http://test.com/attendee/join")
      post :auth, :id => room.to_param, :user => hash
    end

    it "redirects to the correct join_url" do
      hash = { :name => "Elftor", :password => room.attendee_password }
      mocked_api.should_receive(:is_meeting_running?).and_return(true)
      mocked_api.should_receive(:join_meeting_url).and_return("http://test.com/attendee/join")
      post :auth, :id => room.to_param, :user => hash
      should respond_with(:redirect)
      should redirect_to("http://test.com/attendee/join")
    end

    it "uses bigbluebutton_role when the return is not :password" do
      controller.stub(:bigbluebutton_role) { :attendee }
      hash = { :name => "Elftor", :password => nil }
      mocked_api.should_receive(:is_meeting_running?).and_return(true)
      mocked_api.should_receive(:join_meeting_url).
        with(anything, anything, room.attendee_password).
        and_return("http://test.com/attendee/join")
      post :auth, :id => room.to_param, :user => hash
      should respond_with(:redirect)
      should redirect_to("http://test.com/attendee/join")
      should assign_to(:user_role).with(:attendee)
    end

    context "validates user input and shows error" do
      before { controller.should_receive(:bigbluebutton_role).once { :password } }
      before(:each) { post :auth, :id => room.to_param, :user => user_hash }

      context "when name is not set" do
        let(:user_hash) { { :password => room.moderator_password } }
        it { should respond_with(:unauthorized) }
        it { should assign_to(:room).with(room) }
        it { should assign_to(:user_role).with(:password) }
        it { should render_template(:invite) }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.failure')) }
      end

      context "when name is set but empty" do
        let(:user_hash) { { :password => room.moderator_password, :name => "" } }
        it { should respond_with(:unauthorized) }
        it { should assign_to(:room).with(room) }
        it { should assign_to(:user_role).with(:password) }
        it { should render_template(:invite) }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.failure')) }
      end

      context "when the password is wrong" do
        let(:user_hash) { { :name => "Elftor", :password => nil } }
        it { should respond_with(:unauthorized) }
        it { should assign_to(:user_role).with(:password) }
        it { should assign_to(:room).with(room) }
        it { should render_template(:invite) }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.failure')) }
      end
    end

    context "calls #join_internal" do
      let(:user) { FactoryGirl.build(:user) }
      let(:hash) { { :name => user.name, :password => room.moderator_password } }
      before {
        controller.stub(:bigbluebutton_user) { nil }
        controller.stub(:bigbluebutton_role) { :moderator }
        controller.stub(:render) # prevent ActionView::MissingTemplate
        controller.should_receive(:join_internal)
          .with(user.name, :moderator, nil, :invite)
      }
      it { post :auth, :id => room.to_param, :user => hash }
    end
  end

  describe "#external" do
    let(:server) { FactoryGirl.create(:bigbluebutton_server) }
    let(:meetingid) { 'my-meeting-id' }

    context "on success" do
      before {
        controller.stub(:bigbluebutton_user).and_return(nil)
        BigbluebuttonServer.stub(:find).and_return(server)
      }
      before(:each) { get :external, :meeting => meetingid, :server_id => server.id }
      it { should respond_with(:success) }
      it { should render_template(:external) }
      it { should assign_to(:server).with(server) }
      it { should assign_to(:room).with_kind_of(BigbluebuttonRoom) }
      it { assigns(:room).meetingid.should be(meetingid) }
      it { assigns(:room).server_id.should be(server.id) }
    end

    context "when params[:meeting].blank?" do
      context "without params[:redir_url]" do
        before(:each) { get :external, :server_id => server.id }
        it { should respond_with(:redirect) }
        it { should redirect_to bigbluebutton_rooms_path }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.external.blank_meetingid')) }
      end

      context "with params[:redir_url]" do
        before(:each) { get :external, :server_id => server.id, :redir_url => '/'}
        it { should redirect_to '/' }
      end
    end

    context "when params[:server_id]" do
      it "is blank" do
        lambda {
            get :external, :meeting => meetingid
        }.should raise_error(ActiveRecord::RecordNotFound)
      end

      it "is invalid" do
        lambda {
            get :external, :meeting => meetingid, :server_id => server.id + 10
        }.should raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end # #external

  describe "#external_auth" do
    let(:user) { FactoryGirl.build(:user) }
    let(:user_hash) { { :name => "Any Name", :password => new_room.attendee_password } }
    let(:meetingid) { "my-meeting-id" }
    let(:new_room) { BigbluebuttonRoom.new(:meetingid => meetingid,
                                           :attendee_password => Forgery(:basic).password,
                                           :moderator_password => Forgery(:basic).password,
                                           :server => mocked_server) }
    let(:meetings) { [ new_room ] }
    before { controller.stub(:bigbluebutton_user).and_return(nil) }

    it "shows error when params[:server_id] is invalid" do
      lambda {
        post :external_auth, :meeting => new_room.meetingid, :server_id => nil, :user => user_hash
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

    context "assigns @server and @room if params[:meeting] and params[:user] and params[:server_id]" do
      before {
        controller.should_receive(:set_request_headers)
        mock_server_and_api
        mocked_server.should_receive(:fetch_meetings)
        mocked_server.should_receive(:meetings).and_return(meetings)
        new_room.should_receive(:fetch_is_running?)
        new_room.should_receive(:is_running?).and_return(true)
        new_room.should_receive(:join_url)
      }
      before(:each) { post :external_auth, :meeting => new_room.meetingid, :server_id => mocked_server.id, :user => user_hash }
      it { should assign_to(:room).with(new_room) }
      it { should assign_to(:server).with(mocked_server) }
    end

    context "shows error" do
      let(:http_referer) { bigbluebutton_server_path(mocked_server) }
      before {
        controller.should_receive(:set_request_headers)
        mock_server_and_api
        request.env["HTTP_REFERER"] = http_referer
      }

      context "if not params[:meeting]" do
        let(:message) { I18n.t('bigbluebutton_rails.rooms.errors.external.wrong_params') }
        before(:each) { post :external_auth, :meeting => nil, :server_id => mocked_server.id, :user => user_hash }
        it { should assign_to(:room).with(nil) }
        it { should respond_with(:redirect) }
        it { should redirect_to(http_referer) }
        it { should set_the_flash.to(message) }
      end

      context "if not params[:user]" do
        let(:message) { I18n.t('bigbluebutton_rails.rooms.errors.external.wrong_params') }
        before(:each) { post :external_auth, :meeting => new_room.meetingid, :server_id => mocked_server.id, :user => nil }
        it { should assign_to(:room).with(nil) }
        it { should respond_with(:redirect) }
        it { should redirect_to(http_referer) }
        it { should set_the_flash.to(message) }
      end
    end

    context "with @server and @room assigned" do
      before {
        controller.should_receive(:set_request_headers)
        mock_server_and_api
        mocked_server.should_receive(:fetch_meetings)
        mocked_server.should_receive(:meetings).and_return(meetings)
      }

      it "block access if bigbluebutton_role returns nil" do
        controller.stub(:bigbluebutton_role) { nil }
        lambda {
          post :external_auth, :meeting => new_room.meetingid, :server_id => mocked_server.id, :user => user_hash
        }.should raise_error(BigbluebuttonRails::RoomAccessDenied)
      end

      context "validates user input and shows error" do
        before(:each) { post :external_auth, :meeting => new_room.meetingid, :server_id => mocked_server.id, :user => user_hash }

        context "when name is not set" do
          let(:user_hash) { { :password => room.moderator_password } }
          it { should respond_with(:unauthorized) }
          it { should assign_to(:room).with(new_room) }
          it { should render_template(:external) }
          it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.failure')) }
        end

        context "when name is empty not set" do
          let(:user_hash) { { :password => room.moderator_password, :name => "" } }
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
      end

      it "if there's a user logged, should use his name and id" do
        user = FactoryGirl.build(:user)
        controller.stub(:bigbluebutton_user).and_return(user)
        controller.stub(:render) # prevent ActionView::MissingTemplate
        controller.should_receive(:join_internal)
          .with(user.name, anything, user.id, anything) # here's the validation
        post :external_auth, :meeting => new_room.meetingid, :server_id => mocked_server.id, :user => user_hash
      end

    end

    context "calls #join_internal" do
      let(:user) { FactoryGirl.build(:user) }
      before {
        mock_server_and_api
        mocked_server.should_receive(:fetch_meetings)
        mocked_server.should_receive(:meetings).and_return(meetings)
        controller.stub(:render) # prevent ActionView::MissingTemplate
        controller.should_receive(:join_internal)
          .with(user_hash[:name], :attendee, nil, :external)
      }
      it { post :external_auth, :meeting => new_room.meetingid,
                                :server_id => mocked_server.id,
                                :user => user_hash
      }
    end

  end # #external_auth

  describe "#fetch_recordings" do
    # setup basic server and API mocks
    before do
      #controller.should_receive(:set_request_headers)
      mock_server_and_api
    end
    let(:filter) {
      { :meetingID => room.meetingid }
    }

    context "on success" do
      before(:each) {
        mocked_server.should_receive(:fetch_recordings).with(filter)
        post :fetch_recordings, :id => room.to_param
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_room_path(room) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.fetch_recordings.success')) }
    end

    context "on BigBlueButtonException" do
      let(:bbb_error_msg) { SecureRandom.hex(250) }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
      before(:each) {
        mocked_server.should_receive(:fetch_recordings) { raise bbb_error }
        post :fetch_recordings, :id => room.to_param
      }
      it { should respond_with(:redirect) }
      it { should redirect_to(bigbluebutton_room_path(room)) }
      it { should set_the_flash.to(bbb_error_msg[0..200]) }
    end

    context "if the room has no server associated" do
      before(:each) {
        room.stub(:server) { nil }
        post :fetch_recordings, :id => room.to_param
      }
      it { should respond_with(:redirect) }
      it { should redirect_to(bigbluebutton_room_path(room)) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.error.fetch_recordings.no_server')) }
    end
  end

  describe "#recordings" do
    before do
      @recording1 = FactoryGirl.create(:bigbluebutton_recording, :room => room)
      @recording2 = FactoryGirl.create(:bigbluebutton_recording, :room => room)
      FactoryGirl.create(:bigbluebutton_recording)

      # one that belongs to another room in the same server
      room2 = FactoryGirl.create(:bigbluebutton_room, :server => room.server)
      FactoryGirl.create(:bigbluebutton_recording, :room => room2)
    end
    before(:each) { get :recordings, :id => room.to_param }
    it { should respond_with(:success) }
    it { should render_template(:recordings) }
    it { should assign_to(:recordings).with([@recording1, @recording2]) }
  end

  describe "before filter :set_request_headers" do
    let(:headers) { {"x-forwarded-for" => "0.0.0.0"} }
    before {
      mock_server_and_api
    }

    let(:make_request) {  }

    # uses any action that triggers this before filter
    # just to make sure the before filter won't break before an action that is not covered
    # by the find_room filter
    context "when @room is nil" do
      before {
        controller.should_receive(:set_request_headers)
        request.env["HTTP_REFERER"] = "/any"
      }
      before(:each) { post :external_auth, :server_id => mocked_server.id }
      it { should redirect_to("/any") }
    end

    # uses any action that triggers this before filter
    context "when @room is valid" do
      before {
        BigbluebuttonRoom.stub(:find_by_param).and_return(room)
        room.should_receive(:fetch_is_running?).and_return(false)
      }
      it {
        get :running, :id => room.to_param
        room.request_headers.should == headers
      }
    end
  end

  # Test #join_internal using #join because it's easier and cleaner than the other
  # actions that also call #join_internal.
  describe "#join_internal" do
    let(:user) { FactoryGirl.build(:user) }
    before {
      controller.stub(:bigbluebutton_user).and_return(user)
      controller.stub(:bigbluebutton_role).and_return(:attendee)
      BigbluebuttonRoom.stub(:find_by_param).and_return(room)
      controller.send(:find_room)
    }

    context "when the user has permission to create the meeting" do
      before {
        room.should_receive(:fetch_is_running?)
        room.should_receive(:is_running?).and_return(false)
        controller.stub(:bigbluebutton_can_create?).with(room, :attendee)
          .and_return(true)
        room.should_receive(:create_meeting)
          .with(user.name, user.id, controller.request)
        room.should_receive(:join_url).and_return("http://test.com/join/url")
      }
      before(:each) { get :join, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to("http://test.com/join/url") }
    end

    context "when the user doesn't have permission to create the meeting" do
      before {
        room.should_receive(:fetch_is_running?)
        room.should_receive(:is_running?).and_return(false)
        controller.stub(:bigbluebutton_can_create?).with(room, :attendee)
          .and_return(false)
        room.should_not_receive(:create_meeting)
      }
      before(:each) { get :join, :id => room.to_param }
      it { should respond_with(:success) }
      it { should render_template(:join) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.cannot_create')) }
    end

    context "when the user has permission to join the meeting" do
      before {
        room.should_receive(:fetch_is_running?)
        room.should_receive(:is_running?).and_return(true)
        room.should_not_receive(:create_meeting)
        room.should_receive(:join_url)
          .with(user.name, :attendee)
          .and_return("http://test.com/join/url")
      }
      before(:each) { get :join, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to("http://test.com/join/url") }
    end

    context "when the user doesn't have permission to join the meeting" do
      before {
        room.should_receive(:fetch_is_running?)
        room.should_receive(:is_running?).and_return(true)
        room.should_not_receive(:create_meeting)
        room.should_receive(:join_url)
          .with(user.name, :attendee)
          .and_return(nil)
      }
      before(:each) { get :join, :id => room.to_param }
      it { should respond_with(:success) }
      it { should render_template(:join) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.not_running')) }
    end

    context "when the param ':mobile' is set" do
      before {
        room.should_receive(:fetch_is_running?)
        room.should_receive(:is_running?).and_return(true)
        room.should_not_receive(:create_meeting)
        room.should_receive(:join_url)
          .and_return("http://test.com/join/url")
      }
      let(:mobile_flag) { true }
      before(:each) { get :join, :id => room.to_param, :mobile => true }
      it { should respond_with(:redirect) }
      it { should redirect_to("bigbluebutton://test.com/join/url") }
    end

    context "when an exception is thrown" do
      let(:bbb_error_msg) { SecureRandom.hex(250) }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
      before {
        request.env["HTTP_REFERER"] = "/any"
        room.should_receive(:fetch_is_running?) { raise bbb_error }
      }
      before(:each) { get :join, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should set_the_flash.to(bbb_error_msg[0..200]) }
    end
  end

end
