require 'spec_helper'

describe Bigbluebutton::RecordingsController do
  render_views
  let(:recording) { FactoryGirl.create(:bigbluebutton_recording) }

  describe "#index" do
    before { 3.times { FactoryGirl.create(:bigbluebutton_recording) } }
    before(:each) { get :index }
    it { should respond_with(:success) }
    it { should assign_to(:recordings).with(BigbluebuttonRecording.all) }
    it { should render_template(:index) }
  end

  describe "#show" do
    before(:each) { get :show, :id => recording.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:recording).with(recording) }
    it { should render_template(:show) }
  end

  describe "#edit" do
    before(:each) { get :edit, :id => recording.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:recording).with(recording) }
    it { should render_template(:edit) }
  end

  describe "#update" do
    let(:new_recording) { FactoryGirl.build(:bigbluebutton_recording) }
    before { @recording = recording } # need this to trigger let(:recording) and actually create the object

    context "on success" do
      before :each do
        expect {
          put :update, :id => @recording.to_param, :bigbluebutton_recording => new_recording.attributes
        }.not_to change{ BigbluebuttonRecording.count }
      end
      it {
        saved = BigbluebuttonRecording.find(@recording)
        should respond_with(:redirect)
        should redirect_to(bigbluebutton_recording_path(saved))
      }
      it {
        saved = BigbluebuttonRecording.find(@recording)
        new_recording.room_id = saved.room_id # this attribute is protected, so wasn't updated
        saved.should have_same_attributes_as(new_recording)
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.recordings.notice.update.success')) }
    end

    context "on failure" do
      before :each do
        new_recording.recordingid = nil # invalid
        put :update, :id => @recording.to_param, :bigbluebutton_recording => new_recording.attributes
      end
      it { should render_template(:edit) }
      it { should assign_to(:recording).with(@recording) }
    end
  end

  describe "#destroy" do
    before { mock_server_and_api }

    context "on success" do
      before(:each) {
        mocked_server.should_receive(:send_delete_recordings).with(recording.recordingid)
        expect {
          delete :destroy, :id => recording.to_param
        }.to change{ BigbluebuttonRecording.count }.by(-1)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_recordings_url }
    end

    context "on failure" do
      let(:bbb_error_msg) { "err msg" }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
      before {
        mocked_server.should_receive(:send_delete_recordings) { raise bbb_error }
      }
      before(:each) {
        expect {
          delete :destroy, :id => recording.to_param
        }.to change{ BigbluebuttonRecording.count }.by(-1)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_recordings_url }
      it {
        msg = I18n.t('bigbluebutton_rails.recordings.notice.destroy.success_with_bbb_error', :error => bbb_error_msg)
        should set_the_flash.to(msg)
      }
    end

    context "with :redir_url" do
      before(:each) {
        expect {
          mocked_server.should_receive(:send_delete_recordings)
          delete :destroy, :id => recording.to_param, :redir_url => bigbluebutton_servers_path
        }.to change{ BigbluebuttonRecording.count }.by(-1)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_servers_path }
    end
  end

end
