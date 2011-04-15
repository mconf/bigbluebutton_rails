require 'spec_helper'
require 'bigbluebutton-api'

def build_running_json(value, error=nil)
  hash = { :running => "#{value}" }
  hash[:error] = error unless error.nil?
  hash.to_json
end

describe Bigbluebutton::RoomsController do

  render_views
  let(:server) { Factory.create(:bigbluebutton_server) }
  let(:room) { Factory.create(:bigbluebutton_room, :server => server) }
  let(:private_room) { Factory.create(:bigbluebutton_room, :server => server, :private => true) }

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
    let(:new_room) { Factory.build(:bigbluebutton_room, :server => server) }

    context do
      before :each do
        expect {
          post :create, :server_id => server.to_param, :bigbluebutton_room => new_room.attributes
        }.to change{ BigbluebuttonRoom.count }.by(1)
      end
      it {
        should respond_with(:redirect)
        should redirect_to(bigbluebutton_server_room_path(server, BigbluebuttonRoom.last))
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.create.success')) }
      it { should assign_to(:server).with(server) }
      it {
        saved = BigbluebuttonRoom.last
        saved.should have_same_attributes_as(new_room)
      }
    end

    context "when meeting_id is not specified should copied from name" do
      before :each do
        attr = new_room.attributes
        attr.delete("meeting_id")
        post :create, :server_id => server.to_param, :bigbluebutton_room => attr
      end
      it {
        saved = BigbluebuttonRoom.last
        new_room.meeting_id = new_room.name
        saved.should have_same_attributes_as(new_room)
      }
    end
  end

  describe "#update" do
    let(:new_room) { Factory.build(:bigbluebutton_room) }
    before { @room = room }

    context do
      before :each do
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
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.update.success')) }
      it { should assign_to(:server).with(server) }
    end

    context "when meeting_id is not specified should copied from name" do
      before :each do
        attr = new_room.attributes
        attr.delete("meeting_id")
        put :update, :server_id => server.to_param, :id => @room.to_param, :bigbluebutton_room => attr
      end
      it {
        saved = BigbluebuttonRoom.find(@room)
        new_room.meeting_id = new_room.name
        saved.should have_same_attributes_as(new_room)
      }
    end

  end

  describe "#destroy" do
    before {
      mock_server_and_api
      # to make sure it calls end_meeting if the meeting is running
      mocked_api.should_receive(:is_meeting_running?).and_return(true)
      mocked_api.should_receive(:end_meeting).with(room.meeting_id, room.moderator_password)
    }

    before :each do
      expect {
        delete :destroy, :server_id => mocked_server.to_param, :id => room.to_param
      }.to change{ BigbluebuttonRoom.count }.by(-1)
    end
    it {
      should respond_with(:redirect)
      should redirect_to(bigbluebutton_server_rooms_path)
    }
    it { should assign_to(:server).with(mocked_server) }
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
    before { controller.stub(:bigbluebutton_user) { user } }

    # mock the server so we can mock the BBB API
    # we don't want to trigger real API calls here (this is done in the integration tests)

    before { mock_server_and_api }

    context "for a private room" do
      before(:each) { get :join, :server_id => mocked_server.to_param, :id => private_room.to_param }

      it {
        should respond_with(:redirect)
        should redirect_to(invite_bigbluebutton_server_room_path(mocked_server, private_room))
      }
    end

    context "for a public room" do

      context "if the user is a moderator" do
        before {
          controller.should_receive(:bigbluebutton_role).with(room).and_return(:moderator)
          mocked_api.should_receive(:join_meeting_url).with(room.meeting_id, user.name, room.moderator_password).
            and_return("http://test.com/mod/join")
        }

        context "and the conference is running" do
          before {
            mocked_api.should_receive(:is_meeting_running?).and_return(true)
          }

          it "assigns server" do
            get :join, :server_id => mocked_server.to_param, :id => room.to_param
            should assign_to(:server).with(mocked_server)
          end

          it "redirects to the moderator join url" do
            get :join, :server_id => mocked_server.to_param, :id => room.to_param
            should respond_with(:redirect)
            should redirect_to("http://test.com/mod/join")
          end
        end

        context "and the conference is NOT running" do
          before {
            mocked_api.should_receive(:is_meeting_running?).and_return(false)
          }

          it "creates the conference" do
            mocked_api.should_receive(:create_meeting).
              with(room.name, room.meeting_id, room.moderator_password,
                   room.attendee_password, room.welcome_msg)
            get :join, :server_id => mocked_server.to_param, :id => room.to_param
          end
        end

      end

      context "if the user is an attendee" do
        before {
          controller.should_receive(:bigbluebutton_role).with(room).and_return(:attendee)
        }

        context "and the conference is running" do
          before {
            mocked_api.should_receive(:is_meeting_running?).and_return(true)
            mocked_api.should_receive(:join_meeting_url).with(room.meeting_id, user.name, room.attendee_password).
              and_return("http://test.com/attendee/join")
          }

          it "assigns server" do
            get :join, :server_id => mocked_server.to_param, :id => room.to_param
            should assign_to(:server).with(mocked_server)
          end

          it "redirects to the attendee join url" do
            get :join, :server_id => mocked_server.to_param, :id => room.to_param
            should respond_with(:redirect)
            should redirect_to("http://test.com/attendee/join")
          end
        end

        context "and the conference is NOT running" do
          before {
            mocked_api.should_receive(:is_meeting_running?).and_return(false)
          }

          it "do not try to create the conference" do
            mocked_api.should_not_receive(:create_meeting)
            get :join, :server_id => mocked_server.to_param, :id => room.to_param
          end

          it "render the join_wait view to wait for a moderator" do
            get :join, :server_id => mocked_server.to_param, :id => room.to_param
            should respond_with(:success)
            should render_template(:join_wait)
          end
        end

      end

    end

  end

  describe "#end" do
    before { mock_server_and_api }

    context "room is running" do
      before {
        mocked_api.should_receive(:is_meeting_running?).and_return(true)
        mocked_api.should_receive(:end_meeting).with(room.meeting_id, room.moderator_password)
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
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.notice.end.not_running')) }
    end
  end

  describe "#invite" do
    before { mock_server_and_api }

    context "for a public room" do
      before(:each) { get :invite, :server_id => mocked_server.to_param, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to(join_bigbluebutton_server_room_path(mocked_server, room)) }
    end

    context "for a private room" do
      before(:each) { get :invite, :server_id => mocked_server.to_param, :id => private_room.to_param }
      it { should respond_with(:success) }
      it { should render_template(:invite) }
      it { should assign_to(:room).with(private_room) }
    end

=begin
    context "a logged user to a public room" do
      before { controller.stub(:bigbluebutton_user) { Factory.build(:user) } }
      before(:each) { get :invite, :server_id => server.to_param, :id => room.to_param }
      it { should respond_with(:redirect) }
      it { should assign_to(:room).with(room) }
    end

    context "an anonymous user to a public room" do
      before { controller.stub(:bigbluebutton_user).and_return(nil) }
      before(:each) { get :invite, :server_id => server.to_param, :id => room.to_param }
      it { should respond_with(:success) }
      it { should render_template(:invite) }
      it { should assign_to(:room).with(room) }
    end

    context "an anonymous user to a private room" do
      before { controller.stub(:bigbluebutton_user).and_return(nil) }
      before(:each) { get :invite, :server_id => server.to_param, :id => private_room.to_param }
      it { should respond_with(:success) }
      it { should render_template(:invite) }
      it { should assign_to(:room).with(private_room) }
    end
=end

  end

  describe "#auth" do
    before { mock_server_and_api }

    context "entering a wrong password" do
      let(:hash) { { :name => "Elftor", :password => nil } }
      before(:each) { post :auth, :server_id => mocked_server.to_param, :id => private_room.to_param, :user => hash }
      it { should respond_with(:unauthorized) }
      it { should assign_to(:room).with(private_room) }
      it { should render_template(:invite) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.alert.auth.failure')) }
    end

    context "entering the attendee password" do
      let(:hash) { { :name => "Elftor", :password => private_room.attendee_password } }

      # OPTMIZE Almost the same tests as in #join. Can they be integrated somehow?
      context "and the conference is running" do
        before {
          mocked_api.should_receive(:is_meeting_running?).and_return(true)
          mocked_api.should_receive(:join_meeting_url).and_return("http://test.com/attendee/join")
        }

        it "assigns server" do
          post :auth, :server_id => mocked_server.to_param, :id => private_room.to_param, :user => hash
          should assign_to(:server).with(mocked_server)
        end

        it "redirects to the attendee join url" do
          post :auth, :server_id => mocked_server.to_param, :id => private_room.to_param, :user => hash
          should respond_with(:redirect)
          should redirect_to("http://test.com/attendee/join")
        end
      end

      context "and the conference is NOT running" do
        before {
          mocked_api.should_receive(:is_meeting_running?).and_return(false)
        }

        it "do not try to create the conference" do
          mocked_api.should_not_receive(:create_meeting)
          post :auth, :server_id => mocked_server.to_param, :id => private_room.to_param, :user => hash
        end

        it "render the join_wait view to wait for a moderator" do
          post :auth, :server_id => mocked_server.to_param, :id => private_room.to_param, :user => hash
          should respond_with(:success)
          should render_template(:join_wait)
        end
      end

    end

    context "entering the moderator password" do
      let(:hash) { { :name => "Elftor", :password => private_room.moderator_password } }

      # OPTMIZE Almost the same tests as in #join. Can they be integrated somehow?
      before {
        mocked_api.should_receive(:join_meeting_url).and_return("http://test.com/mod/join")
      }

      context "and the conference is running" do
        before {
          mocked_api.should_receive(:is_meeting_running?).and_return(true)
        }

        it "assigns server" do
          post :auth, :server_id => mocked_server.to_param, :id => private_room.to_param, :user => hash
          should assign_to(:server).with(mocked_server)
        end

        it "redirects to the moderator join url" do
          post :auth, :server_id => mocked_server.to_param, :id => private_room.to_param, :user => hash
          should respond_with(:redirect)
          should redirect_to("http://test.com/mod/join")
        end
      end

      context "and the conference is NOT running" do
        before {
          mocked_api.should_receive(:is_meeting_running?).and_return(false)
        }

        it "creates the conference" do
          mocked_api.should_receive(:create_meeting).
            with(private_room.name, private_room.meeting_id, private_room.moderator_password,
                 private_room.attendee_password, private_room.welcome_msg)
          post :auth, :server_id => mocked_server.to_param, :id => private_room.to_param, :user => hash
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
        should redirect_to(bigbluebutton_server_rooms_path)
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

end

