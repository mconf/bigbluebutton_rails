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
    let(:http_referer) { bigbluebutton_room_path(room) }
    before {
      request.env["HTTP_REFERER"] = http_referer
      controller.should_receive(:set_request_headers)
      mock_server_and_api
      room.server = mocked_server
      controller.stub(:bigbluebutton_user) { user }
    }

    context "with no parameters in the URL" do
      before {
        controller.should_receive(:join_bigbluebutton_room_url)
          .once.with(room, { "auto_join" => '1' })
          .and_return("http://test.com/join/url?auto_join=1")
        controller.should_receive(:join_bigbluebutton_room_url)
          .once.with(room, { "desktop" => '1' })
          .and_return("http://test.com/join/url?desktop=1")
      }

      before(:each) { get :join_mobile, :id => room.to_param }
      it("is successful") { should respond_with(:success) }
      it("assigns room") { should assign_to(:room).with(room) }
      it("assigns join_mobile") { should assign_to(:join_mobile).with("http://test.com/join/url?auto_join=1") }
      it("assigns join_desktop") { should assign_to(:join_desktop).with("http://test.com/join/url?desktop=1") }
      it { should render_template(:join_mobile) }
    end

    context "with parameters in the URL" do
      before {
        # here are the validations that the parameters received by #join_mobile are used in the URLs
        # it generates
        controller.should_receive(:join_bigbluebutton_room_url)
          .once.with(room, { "user" => { "name" => "Name" }, "redir_url" => http_referer, "auto_join" => '1' })
          .and_return("http://test.com/join/url?auto_join=1")
        controller.should_receive(:join_bigbluebutton_room_url)
          .once.with(room, { "user" => { "name" => "Name" }, "redir_url" => http_referer, "desktop" => '1' })
          .and_return("http://test.com/join/url?desktop=1")
      }

      before(:each) { get :join_mobile, :id => room.to_param, :redir_url => http_referer, :user => { :name => "Name" }, :other => "to-be-removed" }
      it("is successful") { should respond_with(:success) }
      it("assigns room") { should assign_to(:room).with(room) }
      it("assigns join_mobile") { should assign_to(:join_mobile).with("http://test.com/join/url?auto_join=1") }
      it("assigns join_desktop") { should assign_to(:join_desktop).with("http://test.com/join/url?desktop=1") }
      it { should render_template(:join_mobile) }
    end
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
      context "on success" do
        before(:each) {
          expect {
            post :create, :bigbluebutton_room => new_room.attributes, :redir_url => "/any"
          }.to change{ BigbluebuttonRoom.count }.by(1)
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end

      context "on failure" do
        before(:each) {
          new_room.name = nil # invalid
          expect {
            post :create, :bigbluebutton_room => new_room.attributes, :redir_url => "/any"
          }.not_to change{ BigbluebuttonRoom.count }
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
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

    describe "params handling" do
      let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_room) }
      let(:params) { { :bigbluebutton_room => attrs } }
      let(:allowed_params) {
        [ :name, :server_id, :meetingid, :attendee_key, :moderator_key, :welcome_msg,
          :private, :logout_url, :dial_number, :voice_bridge, :max_participants, :owner_id,
          :owner_type, :external, :param, :record_meeting, :duration, :default_layout, :presenter_share_only,
          :auto_start_video, :auto_start_audio, :metadata_attributes => [ :id, :name, :content, :_destroy, :owner_id ] ]
      }

      it {
        # we just check that the rails method 'permit' is being called on the hash with the
        # correct parameters
        room = BigbluebuttonRoom.new
        BigbluebuttonRoom.stub(:new).and_return(room)
        attrs.stub(:permit).and_return(attrs)
        controller.stub(:params).and_return(params)

        post :create, :bigbluebutton_room => attrs
        attrs.should have_received(:permit).with(*allowed_params)
      }
    end

    # to make sure it doesn't break if the hash informed doesn't have the key :bigbluebutton_room
    describe "if parameters are not informed" do
      it {
        expect {
          post :create
        }.not_to change{ BigbluebuttonRoom.count }
        should render_template(:new)
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
      context "on success" do
        before(:each) {
          put :update, :id => @room.to_param, :bigbluebutton_room => new_room.attributes, :redir_url => "/any"
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end

      context "on failure" do
        before(:each) {
          new_room.name = nil # invalid
          put :update, :id => @room.to_param, :bigbluebutton_room => new_room.attributes, :redir_url => "/any"
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
    end

    describe "params handling" do
      let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_room) }
      let(:params) { { :bigbluebutton_room => attrs } }
      let(:allowed_params) {
        [ :name, :server_id, :meetingid, :attendee_key, :moderator_key, :welcome_msg,
          :private, :logout_url, :dial_number, :voice_bridge, :max_participants, :owner_id,
          :owner_type, :external, :param, :record_meeting, :duration, :default_layout, :presenter_share_only,
          :auto_start_video, :auto_start_audio, :metadata_attributes => [ :id, :name, :content, :_destroy, :owner_id ] ]
      }
      it {
        # we just check that the rails method 'permit' is being called on the hash with the
        # correct parameters
        BigbluebuttonRoom.stub(:find_by_param).and_return(@room)
        @room.stub(:update_attributes).and_return(true)
        attrs.stub(:permit).and_return(attrs)
        controller.stub(:params).and_return(params)

        put :update, :id => @room.to_param, :bigbluebutton_room => attrs
        attrs.should have_received(:permit).with(*allowed_params)
      }
    end

    # to make sure it doesn't break if the hash informed doesn't have the key :bigbluebutton_room
    describe "if parameters are not informed" do
      before(:each) {}
      it {
        put :update, :id => @room.to_param
        should redirect_to(bigbluebutton_room_path(@room))
      }
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
        mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_api_password)
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
          delete :destroy, :id => room.to_param, :redir_url => "/any"
        }.to change{ BigbluebuttonRoom.count }.by(-1)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to "/any" }
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
      it { should respond_with_content_type('application/json') }
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
    let(:http_referer) { bigbluebutton_room_path(room) }
    before {
      request.env["HTTP_REFERER"] = http_referer
      controller.should_receive(:set_request_headers)
      mock_server_and_api
    }

    for method in [:get, :post]
      context "via #{method}" do

        context "before filter #join_check_room" do
          let(:user_hash) { { :name => "Elftor", :key => room.attendee_key } }
          let(:meetingid) { "my-meeting-id" }

          context "if params[:id]" do
            before {
              # ignore the join, just need to before filters to run
              controller.should_receive(:join_internal)
              mocked_api.should_receive(:is_meeting_running?).and_return(true)
            }
            before(:each) { send(method, :join, :id => room.to_param, :user => user_hash) }
            it { should assign_to(:room).with(room) }
          end

          context "if params[:id] doesn't exists" do
            let(:message) { I18n.t('bigbluebutton_rails.rooms.errors.join.wrong_params') }
            before(:each) {
              BigbluebuttonRoom.stub(:find_by_param).and_return(nil)
              send(method, :join, :id => "inexistent-room-id", :user => user_hash)
            }
            it { should assign_to(:room).with(nil) }
            it { should respond_with(:redirect) }
            it { should redirect_to(http_referer) }
            it { should set_the_flash.to(message) }
          end
        end

        context "before filter #join_user_params" do

          context "block access if bigbluebutton_role returns nil" do
            let(:hash) { { :name => "Elftor", :key => room.attendee_key } }
            before { controller.stub(:bigbluebutton_role) { nil } }
            it {
              lambda {
                send(method, :join, :id => room.to_param, :user => hash)
              }.should raise_error(BigbluebuttonRails::RoomAccessDenied)
            }
          end

          it "if there's a user logged, should use his name" do
            controller.stub(:bigbluebutton_role) { :key }
            hash = { :name => "Elftor", :key => room.attendee_key }
            controller.stub(:bigbluebutton_user).and_return(user)
            mocked_api.should_receive(:is_meeting_running?).at_least(:once).and_return(true)
            mocked_api.should_receive(:join_meeting_url)
              .with(room.meetingid, user.name, room.attendee_api_password, anything) # here's the validation
              .and_return("http://test.com/attendee/join")
            send(method, :join, :id => room.to_param, :user => hash)
          end

          context "uses bigbluebutton_role when the return is not :key" do
            let(:hash) { { :name => "Elftor", :key => nil } }
            before {
              controller.stub(:bigbluebutton_user).and_return(nil)
              controller.stub(:bigbluebutton_role) { :attendee }
              mocked_api.should_receive(:is_meeting_running?).at_least(:once).and_return(true)
              mocked_api.should_receive(:join_meeting_url)
                .with(anything, anything, room.attendee_api_password, anything)
                .and_return("http://test.com/attendee/join")
            }
            before(:each) { send(method, :join, :id => room.to_param, :user => hash) }
            it { should respond_with(:redirect) }
            it { should redirect_to("http://test.com/attendee/join") }
            it { should assign_to(:user_role).with(:attendee) }
            it { should assign_to(:user_name).with("Elftor") }
            it { should assign_to(:user_id).with(nil) }
          end

          context "validates user input and shows error" do
            before {
              controller.stub(:bigbluebutton_user).and_return(nil)
              controller.should_receive(:bigbluebutton_role).once { :key }
            }
            before(:each) { send(method, :join, :id => room.to_param, :user => user_hash) }

            context "when name is not set" do
              let(:user_hash) { { :key => room.moderator_key } }
              it { should respond_with(:redirect) }
              it { should redirect_to(http_referer) }
              it { should assign_to(:room).with(room) }
              it { should assign_to(:user_role).with(:moderator) }
              it { should assign_to(:user_name).with(nil) }
              it { should assign_to(:user_id).with(nil) }
              it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.join.failure')) }
            end

            context "when name is set but empty" do
              let(:user_hash) { { :key => room.moderator_key, :name => "" } }
              it { should respond_with(:redirect) }
              it { should redirect_to(http_referer) }
              it { should assign_to(:room).with(room) }
              it { should assign_to(:user_role).with(:moderator) }
              it { should assign_to(:user_name).with("") }
              it { should assign_to(:user_id).with(nil) }
              it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.join.failure')) }
            end

            context "when the key is wrong" do
              let(:user_hash) { { :name => "Elftor", :key => nil } }
              it { should respond_with(:redirect) }
              it { should redirect_to(http_referer) }
              it { should assign_to(:user_role).with(nil) }
              it { should assign_to(:user_name).with("Elftor") }
              it { should assign_to(:user_id).with(nil) }
              it { should assign_to(:room).with(room) }
              it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.join.failure')) }
            end
          end

        end

        context "before filter #join_check_can_create" do
          let(:user_hash) { { :key => room.moderator_key, :name => "Elftor" } }
          before {
            controller.stub(:bigbluebutton_user).and_return(nil)
            controller.should_receive(:bigbluebutton_role).once { :moderator }
          }

          context "if the room is not running and the user can't create it" do
            before {
              room.should_receive(:fetch_is_running?).and_return(false)
              controller.should_receive(:bigbluebutton_can_create?)
                .with(room, :moderator)
                .and_return(false)
            }
            before(:each) { send(method, :join, :id => room.to_param, :user => user_hash) }
            it { should respond_with(:redirect) }
            it { should redirect_to(http_referer) }
            it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.join.cannot_create')) }
          end
        end

        context "before filter #join_check_redirect_to_mobile" do
          before {
            mocked_api.should_receive(:is_meeting_running?).at_least(:once).and_return(true)
          }

          context "in a mobile device with no flags set" do
            before {
              controller.stub(:bigbluebutton_role) { :moderator }
              browser = double()
              browser.should_receive(:mobile?).and_return(true)
              controller.stub(:browser).and_return(browser)
            }

            context "with no parameters in the url" do
              before(:each) { send(method, :join, :id => room.to_param) }
              it { should respond_with(:redirect) }
              it { should redirect_to(join_mobile_bigbluebutton_room_path(room, :redir_url => http_referer)) }
            end

            context "with extra parameters in the url it selects only the parameters needed" do
              before(:each) { send(method, :join, :id => room.to_param, :user => { :name => "User name" }, :random => "i-will-be-removed") }
              it { should respond_with(:redirect) }
              it { should redirect_to(join_mobile_bigbluebutton_room_path(room, :user => { :name => "User name" }, :redir_url => http_referer)) }
            end

            context "with a full URL in the request referer it uses only the path in the parameters" do
              before { request.env["HTTP_REFERER"] = "http://mconf.org/webconf/test" }
              before(:each) { send(method, :join, :id => room.to_param) }
              it { should respond_with(:redirect) }
              it { should redirect_to(join_mobile_bigbluebutton_room_path(room, :redir_url => "/webconf/test")) }
            end
          end

          context "when ':auto_join' is set" do
            before {
              controller.stub(:bigbluebutton_user) { user }
              controller.stub(:bigbluebutton_role) { :moderator }

              # make sure it's in a mobile device
              browser = double()
              browser.should_receive(:mobile?).and_return(true)
              controller.stub(:browser).and_return(browser)

              # here's the real verification
              controller.should_receive(:join_internal).with(user.name, :moderator, user.id)
            }
            it { send(method, :join, :id => room.to_param, :auto_join => true) }
          end

          context "when ':desktop' is set" do
            before {
              controller.stub(:bigbluebutton_user) { user }
              controller.stub(:bigbluebutton_role) { :moderator }

              # make sure it's in a mobile device
              browser = double()
              browser.should_receive(:mobile?).and_return(true)
              controller.stub(:browser).and_return(browser)

              # here's the real verification
              controller.should_receive(:join_internal).with(user.name, :moderator, user.id)
            }
            it { send(method, :join, :id => room.to_param, :desktop => true) }
          end

        end

        context "calls #join_internal" do
          before {
            controller.stub(:bigbluebutton_user) { user }
            controller.stub(:bigbluebutton_role) { :moderator }
            mocked_api.should_receive(:is_meeting_running?).at_least(:once).and_return(true)

            # here's the validation
            controller.should_receive(:join_internal)
              .with(user.name, :moderator, user.id)
          }
          it { send(method, :join, :id => room.to_param) }
        end

      end
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
        mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_api_password)
      }
      before(:each) { get :end, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to(bigbluebutton_room_path(room)) }
      it { should assign_to(:room).with(room) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.end.success')) }

    end

    context "with :redir_url" do
      before {
        mocked_api.should_receive(:is_meeting_running?).and_return(true)
        mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_api_password)
      }
      before(:each) { get :end, :id => room.to_param, :redir_url => '/any' }
      it { should respond_with(:redirect) }
      it { should redirect_to('/any') }
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
      context "should be defined with a key" do
        before { controller.stub(:bigbluebutton_role) { :key } }
        before(:each) { get :invite, :id => room.to_param }
        it { should respond_with(:success) }
        it { should render_template(:invite) }
        it { should assign_to(:room).with(room) }
        it { should assign_to(:user_role).with(:key) }
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
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.fetch_recordings.no_server')) }
    end

    context "with :redir_url" do
      context "on success" do
        before(:each) {
          mocked_server.should_receive(:fetch_recordings).with(filter)
          post :fetch_recordings, :id => room.to_param, :redir_url => "/any"
        }
        it {should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
      context "on failure" do
        before(:each) {
          room.stub(:server) { nil }
          post :fetch_recordings, :id => room.to_param, :redir_url => "/any"
        }
        it {should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
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
    let(:make_request) {  }

    # uses any action that does trigger this before filter
    # just to make sure the before filter won't break before an action that is not covered
    # by the find_room filter
    context "when @room is nil" do
      before { request.env["HTTP_REFERER"] = "/any" }
      before(:each) { post :join, :id => 'invalid' }
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
    let(:http_referer) { bigbluebutton_room_path(room) }
    before {
      request.env["HTTP_REFERER"] = http_referer
      controller.stub(:bigbluebutton_user).and_return(user)
      controller.stub(:bigbluebutton_role).and_return(:attendee)
      BigbluebuttonRoom.stub(:find_by_param).and_return(room)
      controller.send(:find_room)
    }

    context "when the user has permission to create the meeting" do
      before {
        room.should_receive(:fetch_is_running?).at_least(:once).and_return(false)
        controller.stub(:bigbluebutton_can_create?).with(room, :attendee)
          .and_return(true)
        controller.stub(:bigbluebutton_create_options).with(room)
          .and_return({ custom: true })
        room.should_receive(:create_meeting)
          .with(user, controller.request, { custom: true })
        room.should_receive(:fetch_new_token).and_return(nil)
        room.should_receive(:join_url).and_return("http://test.com/join/url")
      }
      before(:each) { get :join, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to("http://test.com/join/url") }
    end

    context "when the user doesn't have permission to create the meeting" do
      before {
        room.should_receive(:fetch_is_running?).at_least(:once).and_return(false)
        controller.stub(:bigbluebutton_can_create?).with(room, :attendee)
          .and_return(false)
        room.should_not_receive(:create_meeting)
      }
      before(:each) { get :join, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to(http_referer) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.join.cannot_create')) }
    end

    context "when the user has permission to join the meeting" do
      before {
        room.should_receive(:fetch_is_running?).at_least(:once).and_return(true)
        room.should_not_receive(:create_meeting)
        room.should_receive(:fetch_new_token).and_return(nil)
        room.should_receive(:join_url)
          .with(user.name, :attendee, anything, anything)
          .and_return("http://test.com/join/url")
      }

      context "redirects to the join url" do
        before(:each) { get :join, :id => room.to_param }
        it { should respond_with(:redirect) }
        it { should redirect_to("http://test.com/join/url") }
      end

      context "schedules a BigbluebuttonMeetingUpdater" do
        before(:each) {
          expect {
            get :join, :id => room.to_param
          }.to change{ Resque.info[:pending] }.by(1)
        }
        subject { Resque.peek(:bigbluebutton_rails) }
        it("should have a job schedule") { subject.should_not be_nil }
        it("the job should be the right one") { subject['class'].should eq('BigbluebuttonMeetingUpdater') }
        it("the job should have the correct parameters") { subject['args'].should eq([room.id, 15]) }
      end
    end

    context "gets a new config token before joining" do
      before {
        room.should_receive(:fetch_is_running?).at_least(:once).and_return(true)
        room.should_not_receive(:create_meeting)
      }

      context "if the token is not nil" do
        before(:each) {
          room.should_receive(:fetch_new_token).and_return('fake-token')
          room.should_receive(:join_url)
            .with(user.name, :attendee, nil, hash_including(:configToken  => 'fake-token'))
            .and_return("http://test.com/join/url")
        }
        it("uses the token") { get :join, :id => room.to_param }
      end

      context "if the token is nil" do
        before(:each) {
          room.should_receive(:fetch_new_token).and_return(nil)
          room.should_receive(:join_url)
            .with(user.name, :attendee, nil, {})
            .and_return("http://test.com/join/url")
        }
        it("does not use the token") { get :join, :id => room.to_param }
      end
    end

    context "when the user doesn't have permission to join the meeting" do
      before {
        room.should_receive(:fetch_is_running?).at_least(:once).and_return(true)
        room.should_not_receive(:create_meeting)
        room.should_receive(:fetch_new_token).and_return(nil)
        room.should_receive(:join_url)
          .with(user.name, :attendee, anything, anything)
          .and_return(nil)
      }
      before(:each) { get :join, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to(http_referer) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.join.not_running')) }
    end

    context "in a mobile device" do
      before {
        room.should_receive(:fetch_is_running?).at_least(:once).and_return(true)
        room.should_not_receive(:create_meeting)
        room.should_receive(:fetch_new_token).and_return(nil)
        browser = double()
        browser.should_receive(:mobile?).twice.and_return(true)
        controller.stub(:browser).and_return(browser)
      }

      context "and the url uses 'http'" do
        before {
          room.should_receive(:join_url)
            .and_return("http://test.com/join/url")
        }
        before(:each) { get :join, :id => room.to_param, :auto_join => true }
        it { should respond_with(:redirect) }
        it { should redirect_to("bigbluebutton://test.com/join/url") }
      end

      context "and the url a protocol other than 'http'" do
        before {
          room.should_receive(:join_url)
            .and_return("any://test.com/join/url")
        }
        before(:each) { get :join, :id => room.to_param, :auto_join => true }
        it { should respond_with(:redirect) }
        it { should redirect_to("bigbluebutton://test.com/join/url") }
      end

      context "and the flag :desktop is set" do
        before {
          room.should_receive(:join_url)
            .and_return("http://test.com/join/url")
        }
        before(:each) { get :join, :id => room.to_param, :auto_join => true, :desktop => true }
        it { should respond_with(:redirect) }
        it { should redirect_to("http://test.com/join/url") }
      end
    end

    context "when an exception is thrown" do
      let(:bbb_error_msg) { SecureRandom.hex(250) }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
      before {
        room.should_receive(:fetch_is_running?).at_least(:once).and_return(true)
        room.should_receive(:join_url) { raise bbb_error }
      }
      before(:each) { get :join, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to(http_referer) }
      it { should set_the_flash.to(bbb_error_msg[0..200]) }
    end

  end

end
