require 'spec_helper'
require 'bigbluebutton_api'

# Some tests mock the server and its API object
# We don't want to trigger real API calls here (this is done in the integration tests)

describe Bigbluebutton::MeetingsController do
  let!(:server) { FactoryGirl.create(:bigbluebutton_server) }
  let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting) }

  describe "#destroy" do
    context "on success" do
      before {
        controller.should_receive(:set_request_headers)
        mock_server_and_api
        # to make sure it calls end_meeting if the meeting is running
        mocked_api.should_receive(:is_meeting_running?).and_return(true)
        mocked_api.should_receive(:end_meeting).with(meeting.id, meeting.room.moderator_api_password)
      }
      before(:each) {
        expect {
          delete :destroy, :id => meeting.to_param
        }.to change{ BigbluebuttonRoom.count }.by(-1)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_meetings_url }
    end
  end
end
