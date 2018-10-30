require 'spec_helper'
require 'bigbluebutton_api'

# Some tests mock the server and its API object
# We don't want to trigger real API calls here (this is done in the integration tests)

describe Bigbluebutton::MeetingsController do
  render_views
  let!(:server) { FactoryGirl.create(:bigbluebutton_server) }
  let!(:meeting) { FactoryGirl.create(:bigbluebutton_meeting) }

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

  describe "#edit" do
    context "basic" do
      before(:each) { get :edit, :id => meeting.to_param }
      it { should respond_with(:success) }
      it { should assign_to(:meeting).with(meeting) }
      it { should render_template(:edit) }
    end

    context "doesn't override @meeting" do
      let!(:other_meeting) { FactoryGirl.create(:bigbluebutton_meeting) }
      before { controller.instance_variable_set(:@meeting, other_meeting) }
      before(:each) { get :edit, :id => meeting.to_param }
      it { should assign_to(:meeting).with(other_meeting) }
    end
  end

  describe "#update" do
    let!(:new_meeting) { FactoryGirl.build(:bigbluebutton_meeting) }

    context "on success" do
      before(:each) {
        expect {
          put :update, :id => meeting.to_param, :bigbluebutton_meeting => new_meeting.attributes
        }.not_to change{ BigbluebuttonMeeting.count }
      }
      it { should respond_with(:redirect) }
      it {
        saved = BigbluebuttonMeeting.find(meeting)
        should redirect_to(bigbluebutton_meeting_path(saved))
      }
      it {
        saved = BigbluebuttonMeeting.find(meeting)
        ignored = new_meeting.attributes.keys - ['title'] # only description is editable
        saved.should have_same_attributes_as(new_meeting, ignored)
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.meetings.notice.update.success')) }
    end

    context "on failure" do
      before(:each) {
        BigbluebuttonMeeting.should_receive(:find_by).and_return(meeting)
        meeting.should_receive(:update_attributes).and_return(false)
        put :update, :id => meeting.to_param, :bigbluebutton_meeting => new_meeting.attributes
      }
      it { should render_template(:edit) }
      it { should assign_to(:meeting).with(meeting) }
    end

    describe "params handling" do
      let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_meeting) }
      let(:params) { { :bigbluebutton_meeting => attrs } }
      let(:allowed_params) {
        [:title]
      }
      it {
        # we just check that the rails method 'permit' is being called on the hash with the
        # correct parameters
        BigbluebuttonMeeting.stub(:find_by).and_return(meeting)
        meeting.stub(:update_attributes).and_return(true)
        attrs.stub(:permit).and_return(attrs)
        controller.stub(:params).and_return(params)

        put :update, :id => meeting.to_param, :bigbluebutton_meeting => attrs
        # puts attrs.inspect
        attrs.should have_received(:permit).with(*allowed_params)
      }
    end

    # to make sure it doesn't break if the hash informed doesn't have the key :bigbluebutton_meeting
    describe "if parameters are not informed" do
      it {
        put :update, :id => meeting.to_param
        should redirect_to(bigbluebutton_meeting_path(meeting))
      }
    end

    context "with :redir_url" do
      context "on success" do
        before(:each) {
          put :update, :id => meeting.to_param, :bigbluebutton_meeting => new_meeting.attributes, :redir_url => '/any'
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end

      context "on failure" do
        before(:each) {
          BigbluebuttonMeeting.should_receive(:find_by).and_return(meeting)
          meeting.should_receive(:update_attributes).and_return(false)
          put :update, :id => meeting.to_param, :bigbluebutton_meeting => new_meeting.attributes, :redir_url => '/any'
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
    end

    context "doesn't override @meeting" do
      let!(:other_meeting) { FactoryGirl.create(:bigbluebutton_meeting) }
      before { controller.instance_variable_set(:@meeting, other_meeting) }
      before(:each) { put :update, :id => meeting.to_param, :bigbluebutton_meeting => new_meeting.attributes }
      it { should assign_to(:meeting).with(other_meeting) }
    end
  end




end
