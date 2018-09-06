require 'spec_helper'
require 'bigbluebutton_api'

# Some tests mock the server and its API object
# We don't want to trigger real API calls here (this is done in the integration tests)

describe Bigbluebutton::MeetingsController do
  render_views
  let!(:server) { FactoryGirl.create(:bigbluebutton_server) }

  describe '#destroy' do
    context "when meeting_ended == true" do
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, ended: true) }

      context "when meeting.destroy == true" do
        before {
          request.env["HTTP_REFERER"] = '/any'
          expect {
            delete :destroy, :id => meeting.to_param
          }.to change{ BigbluebuttonMeeting.count }.by(-1)
        }
        it("should decrease meetings count by -1") { }
        it { should redirect_to '/any' }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.meetings.delete.success')) }
      end

      context "when meeting.destroy == false" do
        before {
          request.env["HTTP_REFERER"] = '/any'
          BigbluebuttonMeeting.any_instance.stub(:destroy).and_return(false)
          expect {
            delete :destroy, :id => meeting.to_param
          }.to change{ BigbluebuttonMeeting.count }.by(0)
        }
        it("should not decrease meetings count") { }
        it { should redirect_to '/any' }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.meetings.notice.destroy.error_destroy')) }
      end
    end

    context "When meeting_ended == false" do
      let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting, ended: false) }

      before {
          request.env["HTTP_REFERER"] = '/any'
          BigbluebuttonMeeting.any_instance.stub(:destroy).and_return(false)
          expect {
            delete :destroy, :id => meeting.to_param
          }.to change{ BigbluebuttonMeeting.count }.by(0)
        }
        it("should not decrease meetings count") { }
        it { should redirect_to '/any' }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.meetings.notice.destroy.running.not_ended')) }
    end

  end
end
