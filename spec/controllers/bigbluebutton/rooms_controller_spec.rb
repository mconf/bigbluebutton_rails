require 'spec_helper'
require 'bigbluebutton-api'

# Some tests mock the server and its API object
# We don't want to trigger real API calls here (this is done in the integration tests)

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
    let(:server) { Factory.create(:bigbluebutton_server) }
    let(:room) { Factory.create(:bigbluebutton_room, :server => server) }
    before {
      controller.should_receive(:join_bigbluebutton_server_room_path).
        with(server, room, :mobile => '1').and_return("http://test.com/join/url?mobile=1")
    }
    before(:each) { get :join_mobile, :server_id => server.to_param, :id => room.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
    it { should assign_to(:room).with(room) }
    it { should assign_to(:join_url).with("bigbluebutton://test.com/join/url?mobile=1") }
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
      let(:template) { :join }
      let(:request) { get :join, :server_id => mocked_server.to_param, :id => room.to_param }
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
        get :join, :server_id => mocked_server.to_param, :id => room.to_param, :mobile => "1"
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

    it "if there's a user logged, should use his name" do
      controller.stub(:bigbluebutton_role) { :password }
      hash = { :name => "Elftor", :password => room.attendee_password }
      controller.stub(:bigbluebutton_user).and_return(user)
      mocked_api.should_receive(:is_meeting_running?).and_return(true)
      mocked_api.should_receive(:join_meeting_url).
        with(room.meetingid, user.name, room.attendee_password). # here's the validation
        and_return("http://test.com/attendee/join")
      post :auth, :server_id => mocked_server.to_param, :id => room.to_param, :user => hash
    end

    it "redirects to the correct join_url" do
      hash = { :name => "Elftor", :password => room.attendee_password }
      mocked_api.should_receive(:is_meeting_running?).and_return(true)
      mocked_api.should_receive(:join_meeting_url).and_return("http://test.com/attendee/join")
      post :auth, :server_id => mocked_server.to_param, :id => room.to_param, :user => hash
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
      post :auth, :server_id => mocked_server.to_param, :id => room.to_param, :user => hash
      should respond_with(:redirect)
      should redirect_to("http://test.com/attendee/join")
    end

    context "validates user input and shows error" do
      before { controller.should_receive(:bigbluebutton_role).once { :password } }
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
      let(:template) { :invite }
      let(:hash) { { :name => user.name, :password => room.attendee_password } }
      let(:request) { post :auth, :server_id => mocked_server.to_param, :id => room.to_param, :user => hash }
      before { controller.stub(:bigbluebutton_user).and_return(nil) }
      it_should_behave_like "internal join caller"
    end
  end

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
    let(:user_hash) { { :name => "Elftor", :password => new_room.attendee_password } }
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

    context "got the room" do
      before {
        mocked_server.should_receive(:fetch_meetings)
        mocked_server.should_receive(:meetings).and_return(meetings)
      }

      it "block access if bigbluebutton_role returns nil" do
        controller.stub(:bigbluebutton_role) { nil }
        lambda {
          post :external_auth, :server_id => mocked_server.to_param, :meeting => new_room.meetingid, :user => user_hash
        }.should raise_error(BigbluebuttonRails::RoomAccessDenied)
      end

      it "fetches meeting info" do
        new_room.should_receive(:fetch_meeting_info)
        post :external_auth, :server_id => mocked_server.to_param, :meeting => new_room.meetingid, :user => user_hash
      end

      context "validates user input and shows error" do
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
      end

      context "and the meeting is running" do
        before {
          new_room.should_receive(:fetch_meeting_info)
          new_room.running = true
        }

        it "if there's a user logged, should use his name" do
          controller.stub(:bigbluebutton_user).and_return(user)
          mocked_api.should_receive(:join_meeting_url).
            with(new_room.meetingid, user.name, new_room.attendee_password). # here's the validation
            and_return("http://test.com/attendee/join")
          post :external_auth, :server_id => mocked_server.to_param, :meeting => new_room.meetingid, :user => user_hash
        end

        it "redirects to the correct join_url" do
          controller.stub(:bigbluebutton_user).and_return(user)
          mocked_api.should_receive(:join_meeting_url).
            and_return("http://test.com/attendee/join")
          post :external_auth, :server_id => mocked_server.to_param, :meeting => new_room.meetingid, :user => user_hash
          should respond_with(:redirect)
          should redirect_to("http://test.com/attendee/join")
        end
      end

      context "and the meeting is not running" do
        before {
          new_room.should_receive(:fetch_meeting_info)
          new_room.running = false
        }
        before(:each) { post :external_auth, :server_id => mocked_server.to_param, :meeting => new_room.meetingid, :user => user_hash }
        it { should respond_with(:success) }
        it { should render_template(:external) }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.not_running')) }
      end

    end

  end # #external_auth

  # can be used when matching rooms inside some resource other than servers
  context "selects the first server when the server_id is not defined in the url" do
    let(:server2) { Factory.create(:bigbluebutton_server) }

    # get /users/:user_id/room/:id(.:format)
    before(:each) { get :show, :id => room.to_param, :user_id => "1" }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
  end

end

