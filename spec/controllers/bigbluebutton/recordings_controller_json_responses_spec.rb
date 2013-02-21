require 'spec_helper'

describe Bigbluebutton::RecordingsController do
  render_views
  let(:recording) { FactoryGirl.create(:bigbluebutton_recording) }

  context "json responses for" do

    describe "#index" do
      before do
        @recording1 = FactoryGirl.create(:bigbluebutton_recording)
        @recording2 = FactoryGirl.create(:bigbluebutton_recording)
      end
      before(:each) { get :index, :format => 'json' }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should respond_with_json([@recording1, @recording2].to_json) }
    end

    describe "#show" do
      before(:each) { get :show, :id => recording.to_param, :format => 'json' }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should respond_with_json(recording.to_json) }
    end

    describe "#show" do
      before(:each) { get :show, :id => recording.to_param, :format => 'json' }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should respond_with_json(recording.to_json) }
    end

    describe "#update" do
      let(:new_recording) { FactoryGirl.build(:bigbluebutton_recording) }
      before { @recording = recording }

      context "on success" do
        before(:each) {
          put :update, :id => @recording.to_param, :bigbluebutton_recording => new_recording.attributes, :format => 'json'
        }
        it { should respond_with(:success) }
        it { should respond_with_content_type(:json) }
      end

      context "on failure" do
        before(:each) {
          new_recording.recordid = nil # invalid
          put :update, :id => @recording.to_param, :bigbluebutton_recording => new_recording.attributes, :format => 'json'
        }
        it { should respond_with(:unprocessable_entity) }
        it { should respond_with_content_type(:json) }
        it {
          new_recording.save # should fail
          should respond_with_json(new_recording.errors.full_messages.to_json)
        }
      end
    end

    describe "#destroy" do
      before :each do
        @recording = recording
        @recording.server = nil
        BigbluebuttonRecording.stub(:find_by_recordid) { @recording }
        delete :destroy, :id => @recording.to_param, :format => 'json'
      end
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
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
          before(:each) { post action, :id => recording.to_param, :format => 'json' }
          it { should respond_with(:success) }
          it { should respond_with_content_type(:json) }
          it { should respond_with_json(I18n.t("bigbluebutton_rails.recordings.notice.#{action.to_s}.success")) }
        end

        context "on failure" do
          let(:bbb_error_msg) { SecureRandom.hex(250) }
          let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
          before {
            request.env["HTTP_REFERER"] = "/any"
            mocked_server.should_receive(:send_publish_recordings) { raise bbb_error }
          }
          before(:each) { post action, :id => recording.to_param, :format => 'json' }
          it { should respond_with(:error) }
          it { should respond_with_content_type(:json) }
          it { should respond_with_json(bbb_error_msg[0..200]) }
        end

        context "returns error if there's no server associated" do
          before { recording.stub(:server) { nil } }
          before(:each) { post action, :id => recording.to_param, :format => 'json' }
          it { should respond_with(:error) }
          it { should respond_with_content_type(:json) }
          it { should respond_with_json(I18n.t('bigbluebutton_rails.recordings.errors.check_for_server.no_server')) }
        end
      end
    end

  end
end
