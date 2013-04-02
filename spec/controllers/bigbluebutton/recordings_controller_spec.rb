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
        saved.should have_same_attributes_as(new_recording, ['room_id', 'server_id'])
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.recordings.notice.update.success')) }
    end

    context "on failure" do
      before :each do
        BigbluebuttonRecording.should_receive(:find_by_recordid).and_return(@recording)
        @recording.should_receive(:update_attributes).and_return(false)
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
        mocked_server.should_receive(:send_delete_recordings).with(recording.recordid)
        expect {
          delete :destroy, :id => recording.to_param
        }.to change{ BigbluebuttonRecording.count }.by(-1)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_recordings_url }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.recordings.notice.destroy.success')) }
    end

    context "on failure" do
      let(:bbb_error_msg) { SecureRandom.hex(250) }
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
        msg = I18n.t('bigbluebutton_rails.recordings.notice.destroy.success_with_bbb_error', :error => bbb_error_msg[0..200])
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

    context "when there's no server associated" do
      before(:each) {
        recording.stub(:server) { nil }
        mocked_server.should_not_receive(:send_delete_recordings)
        expect {
          delete :destroy, :id => recording.to_param
        }.to change{ BigbluebuttonRecording.count }.by(-1)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_recordings_url }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.recordings.notice.destroy.success')) }
    end
  end

  describe "#play" do
    context do
      before {
        @format1 = FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording)
        @format2 = FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording)
      }

      context "when params[:type] is specified" do
        before(:each) { get :play, :id => recording.to_param, :type => @format2.format_type }
        it { should respond_with(:redirect) }
        it { should redirect_to @format2.url }
      end

      context "when params[:type] is not specified plays the first format" do
        before(:each) { get :play, :id => recording.to_param }
        it { should respond_with(:redirect) }
        it { should redirect_to @format1.url }
      end
    end

    context "when a playback format is not found" do
      before(:each) { get :play, :id => recording.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_recording_path(recording) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.recordings.errors.play.no_format')) }
    end
  end

  # these actions are essentially the same
  [:publish, :unpublish].each do |action|
    describe "##{action.to_s}" do
      before { mock_server_and_api }
      let(:flag) { action == :publish ? true : false }

      context "on success" do
        before {
          mocked_server.should_receive(:send_publish_recordings).with(recording.recordid, flag)
        }
        before(:each) { post action, :id => recording.to_param }
        it { should respond_with(:redirect) }
        it { should redirect_to(bigbluebutton_recording_path(recording)) }
        it { should set_the_flash.to(I18n.t("bigbluebutton_rails.recordings.notice.#{action.to_s}.success")) }
      end

      context "on failure" do
        let(:bbb_error_msg) { SecureRandom.hex(250) }
        let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
        before {
          request.env["HTTP_REFERER"] = "/any"
          mocked_server.should_receive(:send_publish_recordings) { raise bbb_error }
        }
        before(:each) { post action, :id => recording.to_param }
        it { should respond_with(:redirect) }
        it { should redirect_to(bigbluebutton_recording_path(recording)) }
        it { should set_the_flash.to(bbb_error_msg[0..200]) }
      end

      context "returns error if there's no server associated" do
        before { recording.stub(:server) { nil } }
        before(:each) { post action, :id => recording.to_param }
        it { should respond_with(:redirect) }
        it { should redirect_to(bigbluebutton_recording_path(recording)) }
        it { should set_the_flash.to(I18n.t('bigbluebutton_rails.recordings.errors.check_for_server.no_server')) }
      end
    end
  end

end
