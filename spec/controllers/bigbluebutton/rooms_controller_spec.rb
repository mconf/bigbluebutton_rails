require 'spec_helper'
require 'bigbluebutton_api'

# Some tests mock the server and its API object
# We don't want to trigger real API calls here (this is done in the integration tests)

describe Bigbluebutton::RoomsController do
  render_views
  let(:server) { Factory.create(:bigbluebutton_server) }
  let(:room) { Factory.create(:bigbluebutton_room, :server => server) }

  describe "#index" do
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
    let(:user) { Factory.build(:user) }
    let(:room) { Factory.create(:bigbluebutton_room) }
    before {
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
    let(:new_room) { Factory.build(:bigbluebutton_room, :server => server) }

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
    let(:new_room) { Factory.build(:bigbluebutton_room) }
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

    context "when meetingid is not specified should copied from name" do
      before :each do
        attr = new_room.attributes
        attr.delete("meetingid")
        put :update, :id => @room.to_param, :bigbluebutton_room => attr
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
          delete :destroy, :id => room.to_param
        }.to change{ BigbluebuttonRoom.count }.by(-1)
      end
      it {
        should respond_with(:redirect)
        should redirect_to bigbluebutton_rooms_url
      }
    end

    it "with :redir_url" do
      expect {
        delete :destroy, :id => room.to_param, :redir_url => bigbluebutton_servers_path
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
  end

  describe "#join" do
    let(:user) { Factory.build(:user) }
    before { mock_server_and_api }

    context "for an anonymous user" do
      before { controller.stub(:bigbluebutton_user) { nil } }
      before { controller.stub(:bigbluebutton_role) { :moderator } }
      before(:each) { get :join, :id => room.to_param }
      it {
        should respond_with(:redirect)
        should redirect_to(invite_bigbluebutton_room_path(room))
      }
    end

    context "when the user's role" do
      before { controller.stub(:bigbluebutton_user) { user } }

      context "should be defined with a password" do
        before { controller.stub(:bigbluebutton_role) { :password } }
        before(:each) { get :join, :id => room.to_param }
        it { should respond_with(:redirect) }
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

    # verify the behaviour of .join_internal
    # see support/shared_examples/rooms_controller.rb
    context "calling .join_internal" do
      let(:template) { :join }
      let(:request) { get :join, :id => room.to_param }
      before { controller.stub(:bigbluebutton_user).and_return(user) }
      it_should_behave_like "internal join caller"
    end

    context "when :mobile => true" do
      before {
        controller.stub(:bigbluebutton_user) { user }
        controller.stub(:bigbluebutton_role) { :moderator }
        BigbluebuttonRoom.stub(:find_by_param).and_return(room)
        room.should_receive(:perform_join).and_return("http://test.com/join/url")
      }
      before(:each) {
        get :join, :id => room.to_param, :mobile => "1"
      }
      it { should redirect_to("bigbluebutton://test.com/join/url") }
    end

  end

  describe "#end" do
    before { mock_server_and_api }

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
      before { mocked_api.should_receive(:is_meeting_running?).and_return(false) }
      before(:each) { get :end, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.end.not_running')) }
    end
  end

  describe "#invite" do
    before { mock_server_and_api }
    let(:user) { Factory.build(:user) }
    before { controller.stub(:bigbluebutton_user).and_return(user) }

    context "when the parameter mobile is set" do
      before(:each) { get :invite, :id => room.to_param, :mobile => true }
      it { should respond_with(:success) }
      it { should render_template(:invite) }
      it { should assign_to(:mobile).with(true) }
    end

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
        before(:each) { post :auth, :id => room.to_param, :user => user_hash }
        it { should assign_to(:room).with(room) }
      end

      context "if params[:id] doesn't exists" do
        let(:message) { I18n.t('bigbluebutton_rails.rooms.errors.auth.wrong_params') }
        before(:each) { post :auth, :id => "inexistent-room-id", :user => user_hash }
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

    it "use bigbluebutton_role when the return is diferent of password" do
      controller.stub(:bigbluebutton_role) { :attendee }
      hash = { :name => "Elftor", :password => nil }
      mocked_api.should_receive(:is_meeting_running?).and_return(true)
      mocked_api.should_receive(:join_meeting_url).
        with(anything, anything, room.attendee_password).
        and_return("http://test.com/attendee/join")
      post :auth, :id => room.to_param, :user => hash
      should respond_with(:redirect)
      should redirect_to("http://test.com/attendee/join")
    end

    context "validates user input and shows error" do
      before { controller.should_receive(:bigbluebutton_role).once { :password } }
      before(:each) { post :auth, :id => room.to_param, :user => user_hash }

      context "when name is not set" do
        let(:user_hash) { { :password => room.moderator_password } }
        it { should respond_with(:unauthorized) }
        it { should assign_to(:room).with(room) }
        it { should render_template(:invite) }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.failure')) }
      end

      context "when name is set but empty" do
        let(:user_hash) { { :password => room.moderator_password, :name => "" } }
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
      let(:template) { :invite }
      let(:hash) { { :name => user.name, :password => room.attendee_password } }
      let(:request) { post :auth, :id => room.to_param, :user => hash }
      before { controller.stub(:bigbluebutton_user).and_return(nil) }
      it_should_behave_like "internal join caller"
    end
  end

  describe "#external" do
    let(:server) { Factory.create(:bigbluebutton_server) }
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
    let(:user_hash) { { :name => "Any Name", :password => new_room.attendee_password } }
    let(:meetingid) { "my-meeting-id" }
    let(:new_room) { BigbluebuttonRoom.new(:meetingid => meetingid,
                                           :attendee_password => Forgery(:basic).password,
                                           :moderator_password => Forgery(:basic).password,
                                           :server => mocked_server) }
    let(:meetings) { [ new_room ] }
    before { controller.stub(:bigbluebutton_user).and_return(nil) }

    context "assigns @server and @room if params[:meeting] and params[:user] and params[:server_id]" do
      before {
        mock_server_and_api
        mocked_server.should_receive(:fetch_meetings)
        mocked_server.should_receive(:meetings).and_return(meetings)
        new_room.should_receive(:perform_join)
      }
      before(:each) { post :external_auth, :meeting => new_room.meetingid, :server_id => mocked_server.id, :user => user_hash }
      it { should assign_to(:room).with(new_room) }
      it { should assign_to(:server).with(mocked_server) }
    end

    it "shows error when params[:server_id] is invalid" do
      lambda {
        post :external_auth, :meeting => new_room.meetingid, :server_id => nil, :user => user_hash
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

    context "shows error" do
      let(:http_referer) { bigbluebutton_server_path(mocked_server) }
      before {
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

      context "calls room#perform_join" do
        context "and redirects to the url received" do
          before {
            new_room.should_receive(:perform_join).with(anything, :attendee, request).
              and_return("http://test.com/attendee/join")
          }
          before(:each) { post :external_auth, :meeting => new_room.meetingid, :server_id => mocked_server.id, :user => user_hash }
          it { should respond_with(:redirect) }
          it { should redirect_to("http://test.com/attendee/join") }
        end

        context "and shows error if it returns nil" do
          before {
            new_room.should_receive(:perform_join).with(user_hash[:name], :attendee, request).and_return(nil)
          }
          before(:each) { post :external_auth, :meeting => new_room.meetingid, :server_id => mocked_server.id, :user => user_hash }
          it { should respond_with(:success) }
          it { should render_template(:external) }
          it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.not_running')) }
        end
      end

      it "if there's a user logged, should use his name" do
        user = Factory.build(:user)
        controller.stub(:bigbluebutton_user).and_return(user)
        new_room.should_receive(:perform_join).with(user.name, anything, anything). # here's the validation
          and_return("http://test.com/attendee/join")
        post :external_auth, :meeting => new_room.meetingid, :server_id => mocked_server.id, :user => user_hash
      end

    end

  end # #external_auth

end

