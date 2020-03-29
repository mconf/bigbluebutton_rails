require 'spec_helper'

describe Bigbluebutton::RecordingsController do
  render_views
  let!(:recording) { FactoryGirl.create(:bigbluebutton_recording) }

  describe "#index" do
    context "basic" do
      before { 3.times { FactoryGirl.create(:bigbluebutton_recording) } }
      before(:each) { get :index }
      it { should respond_with(:success) }
      it { should assign_to(:recordings).with(BigbluebuttonRecording.all) }
      it { should render_template(:index) }
    end

    context "doesn't override @recordings" do
      let!(:my_recordings) { [ FactoryGirl.create(:bigbluebutton_recording), FactoryGirl.create(:bigbluebutton_recording) ] }
      before {
        3.times { FactoryGirl.create(:bigbluebutton_recording) }
        controller.instance_variable_set(:@recordings, my_recordings)
      }
      before(:each) { get :index }
      it { should assign_to(:recordings).with(my_recordings) }
    end
  end

  describe "#show" do
    context "basic" do
      before(:each) { get :show, :id => recording.to_param }
      it { should respond_with(:success) }
      it { should assign_to(:recording).with(recording) }
      it { should render_template(:show) }
    end

    context "doesn't override @recording" do
      let!(:other_recording) { FactoryGirl.create(:bigbluebutton_recording) }
      before { controller.instance_variable_set(:@recording, other_recording) }
      before(:each) { get :show, :id => recording.to_param }
      it { should assign_to(:recording).with(other_recording) }
    end
  end

  describe "#edit" do
    context "basic" do
      before(:each) { get :edit, :id => recording.to_param }
      it { should respond_with(:success) }
      it { should assign_to(:recording).with(recording) }
      it { should render_template(:edit) }
    end

    context "doesn't override @recording" do
      let!(:other_recording) { FactoryGirl.create(:bigbluebutton_recording) }
      before { controller.instance_variable_set(:@recording, other_recording) }
      before(:each) { get :edit, :id => recording.to_param }
      it { should assign_to(:recording).with(other_recording) }
    end
  end

  describe "#update" do
    let!(:new_recording) { FactoryGirl.build(:bigbluebutton_recording) }

    context "on success" do
      before(:each) {
        expect {
          put :update, :id => recording.to_param, :bigbluebutton_recording => new_recording.attributes
        }.not_to change{ BigbluebuttonRecording.count }
      }
      it { should respond_with(:redirect) }
      it {
        saved = BigbluebuttonRecording.find(recording)
        should redirect_to(bigbluebutton_recording_path(saved))
      }
      it {
        saved = BigbluebuttonRecording.find(recording)
        ignored = new_recording.attributes.keys - ['description'] # only description is editable
        saved.should have_same_attributes_as(new_recording, ignored)
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.recordings.notice.update.success')) }
    end

    context "on failure" do
      before(:each) {
        BigbluebuttonRecording.should_receive(:find_by_recordid).and_return(recording)
        recording.should_receive(:update_attributes).and_return(false)
        put :update, :id => recording.to_param, :bigbluebutton_recording => new_recording.attributes
      }
      it { should render_template(:edit) }
      it { should assign_to(:recording).with(recording) }
    end

    describe "params handling" do
      let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_recording) }
      let(:params) { { :bigbluebutton_recording => attrs } }
      let(:allowed_params) {
        []
      }
      it {
        # we just check that the rails method 'permit' is being called on the hash with the
        # correct parameters
        BigbluebuttonRecording.stub(:find_by_recordid).and_return(recording)
        recording.stub(:update_attributes).and_return(true)
        attrs.stub(:permit).and_return(attrs)
        controller.stub(:params).and_return(params)

        put :update, :id => recording.to_param, :bigbluebutton_recording => attrs
        attrs.should have_received(:permit).with(*allowed_params)
      }
    end

    # to make sure it doesn't break if the hash informed doesn't have the key :bigbluebutton_recording
    describe "if parameters are not informed" do
      it {
        put :update, :id => recording.to_param
        should redirect_to(bigbluebutton_recording_path(recording))
      }
    end

    context "with :redir_url" do
      context "on success" do
        before(:each) {
          put :update, :id => recording.to_param, :bigbluebutton_recording => new_recording.attributes, :redir_url => '/any'
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end

      context "on failure" do
        before(:each) {
          BigbluebuttonRecording.should_receive(:find_by_recordid).and_return(recording)
          recording.should_receive(:update_attributes).and_return(false)
          put :update, :id => recording.to_param, :bigbluebutton_recording => new_recording.attributes, :redir_url => '/any'
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
    end

    context "doesn't override @recording" do
      let!(:other_recording) { FactoryGirl.create(:bigbluebutton_recording) }
      before { controller.instance_variable_set(:@recording, other_recording) }
      before(:each) { put :update, :id => recording.to_param, :bigbluebutton_recording => new_recording.attributes }
      it { should assign_to(:recording).with(other_recording) }
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
      before { mocked_server.should_receive(:send_delete_recordings) { raise bbb_error } }
      before(:each) {
        expect {
          delete :destroy, :id => recording.to_param
        }.to change{ BigbluebuttonRecording.count }.by(0)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_recordings_url }
      it {
        msg = I18n.t('bigbluebutton_rails.recordings.notice.destroy.success_with_bbb_error', :error => bbb_error_msg[0..200])
        should set_the_flash.to(msg)
      }
    end

    context "with :redir_url" do
      context "on success" do
        before(:each) {
          mocked_server.should_receive(:send_delete_recordings)
          delete :destroy, :id => recording.to_param, :redir_url => "/any"
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end

      context "on failure" do
        let(:bbb_error) { BigBlueButton::BigBlueButtonException.new() }
        before { mocked_server.should_receive(:send_delete_recordings) { raise bbb_error } }
        before(:each) {
          delete :destroy, :id => recording.to_param, :redir_url => "/any"
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
    end

    context "when there's no server associated" do
      before(:each) {
        recording.stub(:server) { nil }
        mocked_server.should_not_receive(:send_delete_recordings)
        expect {
          delete :destroy, :id => recording.to_param
        }.to change{ BigbluebuttonRecording.count }.by(0)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_recordings_url }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.recordings.notice.destroy.success')) }
    end

    context "doesn't override @recording" do
      let!(:other_recording) { FactoryGirl.create(:bigbluebutton_recording) }
      before {
        controller.instance_variable_set(:@recording, other_recording)
        other_recording.server.stub(:send_delete_recordings)
      }
      before(:each) { delete :destroy, :id => recording.to_param }
      it { should assign_to(:recording).with(other_recording) }
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
        context "plays the default format" do
          before {
            @format2.playback_type.update_attributes(default: true)
          }
          before(:each) { get :play, :id => recording.to_param }
          it { should respond_with(:redirect) }
          it { should redirect_to @format2.url }
        end

        context "plays the first format if there's no default" do
          before(:each) { get :play, :id => recording.to_param }
          it { should respond_with(:redirect) }
          it { should redirect_to @format1.url }
        end
      end
    end

    context "when a playback format is not found" do
      before(:each) { get :play, :id => recording.to_param }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_recording_path(recording) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.recordings.errors.play.no_format')) }
    end

    context "with :redir_url" do
      context "on failure" do
        before(:each) { get :play, :id => recording.to_param, :redir_url => '/any' }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
    end

    context "doesn't override @recording" do
      let!(:other_recording) { FactoryGirl.create(:bigbluebutton_recording) }
      let(:format) { FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording) }
      before { controller.instance_variable_set(:@recording, other_recording) }
      before(:each) { get :play, :id => recording.to_param, :type => format.format_type }
      it { should assign_to(:recording).with(other_recording) }
    end

    context "authenticates" do
      let!(:format) { FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording) }

      before { @previous = BigbluebuttonRails.configuration.playback_url_authentication }
      after { BigbluebuttonRails.configuration.playback_url_authentication = @previous }

      context "if authentication is enabled" do
        context "and the token can be fetched" do
          before {
            BigbluebuttonRails.configuration.playback_url_authentication = true
            controller.should_receive(:bigbluebutton_user).and_return('fake-user')
            BigbluebuttonRecording.any_instance.should_receive(:token_url)
              .with('fake-user', request.remote_ip, format)
              .and_return('tokenized-url')
          }
          before(:each) { get :play, :id => recording.to_param, :type => format.format_type }
          it { should respond_with(:redirect) }
          it { should redirect_to 'tokenized-url' }
          it { should assign_to(:playback_url).with('tokenized-url') }
        end

        context "shows an error if the token cannot be fetched" do
          before {
            request.env["HTTP_REFERER"] = '/back'
            BigbluebuttonRails.configuration.playback_url_authentication = true
            controller.should_receive(:bigbluebutton_user).and_return('fake-user')
            BigbluebuttonRecording.any_instance.should_receive(:token_url)
              .with('fake-user', request.remote_ip, format) {
              raise BigBlueButton::BigBlueButtonException.new('test exception')
            }
          }
          before(:each) { get :play, :id => recording.to_param, :type => format.format_type }
          it { should respond_with(:redirect) }
          it { should redirect_to '/back' }
          it { should set_the_flash.to(I18n.t('bigbluebutton_rails.recordings.errors.play.no_token')) }
        end
      end

      context "if authentication is not enabled" do
        before {
          BigbluebuttonRails.configuration.playback_url_authentication = false
          BigbluebuttonRecording.any_instance.should_not_receive(:token_url)
        }
        before(:each) { get :play, :id => recording.to_param, :type => format.format_type }
        it { should respond_with(:redirect) }
        it { should redirect_to format.url }
        it { should assign_to(:playback_url).with(format.url) }
      end
    end

    context "uses an iframe" do
      let!(:format) { FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording) }

      before { @previous = BigbluebuttonRails.configuration.playback_iframe }
      after { BigbluebuttonRails.configuration.playback_iframe = @previous }

      context "if the iframe option is on" do
        before { BigbluebuttonRails.configuration.playback_iframe = true }

        context "and it is downloadable" do
          before {
            format.playback_type.update_attributes(downloadable: true)
            get :play, :id => recording.to_param, :type => format.format_type
          }
          it { should respond_with(:redirect) }
          it { should redirect_to format.url }
        end

        context "and it is not downloadable" do
          before {
            format.playback_type.update_attributes(downloadable: false)
            get :play, :id => recording.to_param, :type => format.format_type
          }
          it { should respond_with(:success) }
          it { should render_template(:play) }
          it { should_not render_with_layout }
        end
      end

      context "if the iframe option is off" do
        before { BigbluebuttonRails.configuration.playback_iframe = false }

        context "and it is downloadable" do
          before {
            format.playback_type.update_attributes(downloadable: true)
            get :play, :id => recording.to_param, :type => format.format_type
          }
          it { should respond_with(:redirect) }
          it { should redirect_to format.url }
        end

        context "and it is not downloadable" do
          before {
            format.playback_type.update_attributes(downloadable: false)
            get :play, :id => recording.to_param, :type => format.format_type
          }
          it { should respond_with(:redirect) }
          it { should redirect_to format.url }
        end
      end
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

      context "with :redir_url" do
        context "on success" do
          before {
            mocked_server.should_receive(:send_publish_recordings).with(recording.recordid, flag)
          }
          before(:each) { post action, :id => recording.to_param, :redir_url => '/any' }
          it { should respond_with(:redirect) }
          it { should redirect_to "/any" }
        end

        context "on failure" do
          let(:bbb_error) { BigBlueButton::BigBlueButtonException.new() }
          before {
            mocked_server.should_receive(:send_publish_recordings) { raise bbb_error }
          }
          before(:each) { post action, :id => recording.to_param, :redir_url => '/any' }
          it { should respond_with(:redirect) }
          it { should redirect_to "/any" }
        end
      end

      context "doesn't override @recording" do
        let!(:other_recording) { FactoryGirl.create(:bigbluebutton_recording) }
        before {
          controller.instance_variable_set(:@recording, other_recording)
          other_recording.server.stub(:send_publish_recordings)
        }
        before(:each) { post action, :id => recording.to_param }
        it { should assign_to(:recording).with(other_recording) }
      end

    end
  end
end
