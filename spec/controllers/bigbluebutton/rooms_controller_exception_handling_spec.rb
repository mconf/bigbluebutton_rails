require 'spec_helper'

describe Bigbluebutton::RoomsController do
  render_views

  # make sure that the exceptions thrown by bigbluebutton-api-ruby are treated by the controller
  context "exception handling" do
    let(:bbb_error_msg) { "err msg" }
    let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
    let(:http_referer) { bigbluebutton_server_path(mocked_server) }
    let(:room) { Factory.create(:bigbluebutton_room, :server => mocked_server) }
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
        delete :destroy, :id => room.to_param
        should respond_with(:redirect)
        should redirect_to bigbluebutton_rooms_url
        should set_the_flash.to(bbb_error_msg)
      end
    end

    describe "#running" do
      before { mocked_api.should_receive(:is_meeting_running?) { raise bbb_error } }
      before(:each) { get :running, :id => room.to_param }
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
        get :end, :id => room.to_param
        should respond_with(:redirect)
        should redirect_to(http_referer)
        should set_the_flash.to(bbb_error_msg)
      end
    end

    describe "#join" do
      before { controller.stub(:bigbluebutton_user) { Factory.build(:user) } }

      context "as moderator" do
        before {
          controller.should_receive(:bigbluebutton_role).with(room).and_return(:moderator)
          room.stub(:select_server).and_return(mocked_server)
          BigbluebuttonRoom.stub(:find_by_param).and_return(room)
        }

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
          get :join, :id => room.to_param
          should respond_with(:redirect)
          should redirect_to(http_referer)
          should set_the_flash.to(bbb_error_msg)
        end

      end

      context "as attendee" do
        before { controller.should_receive(:bigbluebutton_role).with(room).and_return(:attendee) }

        it "catches exception on is_meeting_running" do
          mocked_api.should_receive(:is_meeting_running?) { raise bbb_error }
        end

        it "catches exception on join_meeting_url" do
          mocked_api.should_receive(:is_meeting_running?).and_return(true)
          mocked_api.should_receive(:join_meeting_url) { raise bbb_error }
        end

        after :each do
          get :join, :id => room.to_param
          should respond_with(:redirect)
          should redirect_to(http_referer)
          should set_the_flash.to(bbb_error_msg)
        end
      end

    end # #join

  end
end
