require 'spec_helper'

describe Bigbluebutton::ServersController do
  render_views
  let!(:server) { FactoryGirl.create(:bigbluebutton_server) }

  describe "#index" do
    context "basic" do
      before { 3.times { FactoryGirl.create(:bigbluebutton_server) } }
      before(:each) { get :index }
      it { should respond_with(:success) }
      it { should assign_to(:servers).with(BigbluebuttonServer.all) }
      it { should render_template(:index) }
    end

    context "doesn't override @servers" do
      let!(:my_servers) { [ FactoryGirl.create(:bigbluebutton_server), FactoryGirl.create(:bigbluebutton_server) ] }
      before {
        3.times { FactoryGirl.create(:bigbluebutton_server) }
        controller.instance_variable_set(:@servers, my_servers)
      }
      before(:each) { get :index }
      it { should assign_to(:servers).with(my_servers) }
    end
  end

  describe "#show" do
    context "basic" do
      before(:each) { get :show, :id => server.to_param }
      it { should respond_with(:success) }
      it { should assign_to(:server).with(server) }
      it { should render_template(:show) }
    end

    context "doesn't override @server" do
      let!(:other_server) { FactoryGirl.create(:bigbluebutton_server) }
      before { controller.instance_variable_set(:@server, other_server) }
      before(:each) { get :show, :id => server.to_param }
      it { should assign_to(:server).with(other_server) }
    end
  end

  describe "#new" do
    before(:each) { get :new }
    it { should respond_with(:success) }
    it { should assign_to(:server).with_kind_of(BigbluebuttonServer) }
    it { should render_template(:new) }
  end

  describe "#edit" do
    context "basic" do
      before(:each) { get :edit, :id => server.to_param }
      it { should respond_with(:success) }
      it { should assign_to(:server).with(server) }
      it { should render_template(:edit) }
    end

    context "doesn't override @server" do
      let!(:other_server) { FactoryGirl.create(:bigbluebutton_server) }
      before { controller.instance_variable_set(:@server, other_server) }
      before(:each) { get :edit, :id => server.to_param }
      it { should assign_to(:server).with(other_server) }
    end
  end

  describe "#create" do
    context "on success" do
      before(:each) {
        expect {
          post :create, :bigbluebutton_server => FactoryGirl.attributes_for(:bigbluebutton_server)
        }.to change{ BigbluebuttonServer.count }.by(1)
      }
      it { should respond_with(:redirect) }
      it { should redirect_to(bigbluebutton_server_path(BigbluebuttonServer.last)) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.servers.notice.create.success')) }
    end

    context "on failure" do
      before(:each) {
        attributes = FactoryGirl.attributes_for(:bigbluebutton_server)
        attributes.delete(:url)
        post :create, :bigbluebutton_server => attributes
      }
      it { should render_template(:new) }
    end

    describe "params handling" do
      let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_server) }
      let(:params) { { :bigbluebutton_server => attrs } }
      let(:allowed_params) {
        [ :name, :url, :secret, :param ]
      }

      it {
        # we just check that the rails method 'permit' is being called on the hash with the
        # correct parameters
        server = BigbluebuttonServer.new
        BigbluebuttonServer.stub(:new).and_return(server)
        attrs.stub(:permit).and_return(attrs)
        controller.stub(:params).and_return(params)

        post :create, params
        attrs.should have_received(:permit).with(*allowed_params)
      }
    end

    # to make sure it doesn't break if the hash informed doesn't have the key :bigbluebutton_server
    describe "if parameters are not informed" do
      it {
        put :create
        should render_template(:new)
      }
    end

    context "with :redir_url" do
      context "on success" do
        before(:each) {
          post :create, :bigbluebutton_server => FactoryGirl.attributes_for(:bigbluebutton_server), :redir_url => '/any'
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end

      context "on failure" do
        before(:each) {
          attributes = FactoryGirl.attributes_for(:bigbluebutton_server)
          attributes.delete(:url)
          post :create, :bigbluebutton_server => attributes, :redir_url => '/any'
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
    end

    context "doesn't override @server" do
      let!(:other_server) { FactoryGirl.create(:bigbluebutton_server) }
      before { controller.instance_variable_set(:@server, other_server) }
      before(:each) { post :create, :bigbluebutton_server => FactoryGirl.attributes_for(:bigbluebutton_server) }
      it { should assign_to(:server).with(other_server) }
    end
  end

  describe "#update" do
    let(:new_server) { FactoryGirl.build(:bigbluebutton_server) }

    context "on success" do
      let(:new_server) { FactoryGirl.build(:bigbluebutton_server, version: "") }

      before {
        BigBlueButton::BigBlueButtonApi.any_instance.should_receive(:get_api_version).and_return("0.9")
        expect {
          put :update, id: server.to_param, bigbluebutton_server: new_server.attributes
        }.not_to change { BigbluebuttonServer.count }
      }
      it {
        saved = BigbluebuttonServer.find(server)
        should respond_with(:redirect)
        should redirect_to(bigbluebutton_server_path(saved))
      }
      it {
        saved = BigbluebuttonServer.find(server)
        saved.should_not have_same_attributes_as(new_server)
        saved.version.should == "0.9"
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.servers.notice.update.success')) }
    end

    context "on failure" do
      before :each do
        new_server.url = nil # invalid
        put :update, :id => server.to_param, :bigbluebutton_server => new_server.attributes
      end
      it { should render_template(:edit) }
      it { should assign_to(:server).with(server) }
    end

    describe "params handling" do
      let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_server) }
      let(:params) { { :bigbluebutton_server => attrs } }
      let(:allowed_params) {
        [ :name, :url, :secret, :param ]
      }

      it {
        # we just check that the rails method 'permit' is being called on the hash with the
        # correct parameters
        BigbluebuttonServer.stub(:find_by_param).and_return(server)
        server.stub(:update_attributes).and_return(true)
        attrs.stub(:permit).and_return(attrs)
        controller.stub(:params).and_return(params)

        put :update, :id => server.to_param, :bigbluebutton_server => attrs
        attrs.should have_received(:permit).with(*allowed_params)
      }
    end

    # to make sure it doesn't break if the hash informed doesn't have the key :bigbluebutton_server
    describe "if parameters are not informed" do
      it {
        put :update, :id => server.to_param
        should redirect_to(bigbluebutton_server_path(server))
      }
    end

    context "with :redir_url" do
      context "on success" do
        before(:each) {
          BigbluebuttonServer.any_instance.should_receive(:set_api_version_from_server).and_return(anything)
          put :update, :id => server.to_param, :bigbluebutton_server => new_server.attributes, :redir_url => '/any'
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end

      context "on failure" do
        before(:each) {
          new_server.url = nil # invalid
          put :update, :id => server.to_param, :bigbluebutton_server => new_server.attributes, :redir_url => '/any'
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
    end

    context "doesn't override @server" do
      let!(:other_server) { FactoryGirl.create(:bigbluebutton_server) }
      before { controller.instance_variable_set(:@server, other_server) }
      before(:each) {
        BigbluebuttonServer.any_instance.should_receive(:set_api_version_from_server).and_return(anything)
        put :update, :id => server.to_param, :bigbluebutton_server => new_server.attributes
      }
      it { should assign_to(:server).with(other_server) }
    end
  end

  describe "#destroy" do
    context "on success" do
    before(:each) {
      expect {
        delete :destroy, :id => server.to_param
      }.to change{ BigbluebuttonServer.count }.by(-1)
    }
    it {
      should respond_with(:redirect)
      should redirect_to(bigbluebutton_servers_path)
    }
    end

    context "with :redir_url" do
      context "on success" do
        before(:each) {
          delete :destroy, :id => server.to_param, :redir_url => '/any'
        }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
    end

    context "doesn't override @server" do
      let!(:other_server) { FactoryGirl.create(:bigbluebutton_server) }
      before { controller.instance_variable_set(:@server, other_server) }
      before(:each) { delete :destroy, :id => server.to_param }
      it { should assign_to(:server).with(other_server) }
    end
  end

  describe "#activity" do
    let(:room1) { FactoryGirl.create(:bigbluebutton_room) }
    let(:room2) { FactoryGirl.create(:bigbluebutton_room) }
    before do
      # return our mocked server
      BigbluebuttonServer.stub(:find_by_param).with(server.to_param).
        and_return(server)
    end

    context "standard behaviour" do

      before do
        # mock some methods that trigger API calls
        server.should_receive(:fetch_meetings).and_return({ })
        server.should_receive(:meetings).at_least(:once).and_return([room1, room2])
        room1.should_receive(:fetch_meeting_info)
        room2.should_receive(:fetch_meeting_info)
      end

      context do
        before(:each) { get :activity, :id => server.to_param }
        it { should respond_with(:success) }
        it { should assign_to(:server).with(server) }
        it { should render_template(:activity) }
      end

      context "with params[:update_list]" do
        context "and :format nil" do
          before(:each) { get :activity, :id => server.to_param, :update_list => true }
          it { should render_template('bigbluebutton/servers/_activity_list') }
        end
        context "and :format = 'html'" do
          before(:each) { get :activity, :id => server.to_param, :update_list => true, :format => "html" }
          it { should render_template('bigbluebutton/servers/_activity_list') }
        end
      end
    end

    context "exception handling" do
      let(:bbb_error_msg) { SecureRandom.hex(250) }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }

      context "at fetch_meetings" do
        before { server.should_receive(:fetch_meetings) { raise bbb_error } }
        before(:each) { get :activity, :id => server.to_param }
        it { should set_the_flash.to(bbb_error_msg[0..200]) }
      end

      context "at fetch_meeting_info" do
        before do
          server.should_receive(:fetch_meetings).and_return({ })
          server.should_receive(:meetings).at_least(:once).and_return([room1, room2])
          room1.should_receive(:fetch_meeting_info) { raise bbb_error }
        end
        before(:each) { get :activity, :id => server.to_param }
        it { should set_the_flash.to(bbb_error_msg[0..200]) }
      end
    end

    context "doesn't override @server" do
      let!(:other_server) { FactoryGirl.create(:bigbluebutton_server) }
      before {
        controller.instance_variable_set(:@server, other_server)
        other_server.stub(:fetch_meetings)
      }
      before(:each) { get :activity, :id => server.to_param }
      it { should assign_to(:server).with(other_server) }
    end
  end # #activity

  describe "#publish_recordings" do
    let(:recording_ids) { "id1,id2,id3" }
    before do
      # return our mocked server
      BigbluebuttonServer.stub(:find_by_param).with(server.to_param).and_return(server)
    end

    context "on success" do
      before {
        server.should_receive(:send_publish_recordings).with(recording_ids, true)
      }
      before(:each) { post :publish_recordings, :id => server.to_param, :recordings => recording_ids }
      it { should respond_with(:redirect) }
      it { should redirect_to(recordings_bigbluebutton_server_path(server)) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.servers.notice.publish_recordings.success')) }
    end

    context "on failure" do
      let(:bbb_error_msg) { SecureRandom.hex(250) }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
      before {
        request.env["HTTP_REFERER"] = "/any"
        server.should_receive(:send_publish_recordings) { raise bbb_error }
      }
      before(:each) { post :publish_recordings, :id => server.to_param, :recordings => recording_ids }
      it { should respond_with(:redirect) }
      it { should redirect_to(recordings_bigbluebutton_server_path(server)) }
      it { should set_the_flash.to(bbb_error_msg[0..200]) }
    end

    context "with :redir_url" do
      context "on success" do
        before {
          server.should_receive(:send_publish_recordings).with(recording_ids, true)
        }
        before(:each) { post :publish_recordings, :id => server.to_param, :recordings => recording_ids, :redir_url => '/any' }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end

      context "on failure" do
        let(:bbb_error) { BigBlueButton::BigBlueButtonException.new() }
        before { server.should_receive(:send_publish_recordings) { raise bbb_error } }
        before(:each) { post :publish_recordings, :id => server.to_param, :recordings => recording_ids, :redir_url => '/any' }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
    end

    context "doesn't override @server" do
      let!(:other_server) { FactoryGirl.create(:bigbluebutton_server) }
      before {
        controller.instance_variable_set(:@server, other_server)
        other_server.stub(:send_publish_recordings)
      }
      before(:each) { post :publish_recordings, :id => server.to_param, :recordings => recording_ids }
      it { should assign_to(:server).with(other_server) }
    end
  end

  describe "#unpublish_recordings" do
    let(:recording_ids) { "id1,id2,id3" }
    before do
      # return our mocked server
      BigbluebuttonServer.stub(:find_by_param).with(server.to_param).and_return(server)
    end

    context "on success" do
      before {
        server.should_receive(:send_publish_recordings).with(recording_ids, false)
      }
      before(:each) { post :unpublish_recordings, :id => server.to_param, :recordings => recording_ids }
      it { should respond_with(:redirect) }
      it { should redirect_to(recordings_bigbluebutton_server_path(server)) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.servers.notice.unpublish_recordings.success')) }
    end

    context "on failure" do
      let(:bbb_error_msg) { SecureRandom.hex(250) }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
      before(:each) {
        server.should_receive(:send_publish_recordings) { raise bbb_error }
        post :unpublish_recordings, :id => server.to_param, :recordings => recording_ids
      }
      it { should respond_with(:redirect) }
      it { should redirect_to(recordings_bigbluebutton_server_path(server)) }
      it { should set_the_flash.to(bbb_error_msg[0..200]) }
    end

    context "with :redir_url" do
      context "on success" do
        before {
          server.should_receive(:send_publish_recordings).with(recording_ids, false)
        }
        before(:each) { post :unpublish_recordings, :id => server.to_param, :recordings => recording_ids, :redir_url => '/any' }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end

      context "on failure" do
        let(:bbb_error) { BigBlueButton::BigBlueButtonException.new() }
        before { server.should_receive(:send_publish_recordings) { raise bbb_error } }
        before(:each) { post :unpublish_recordings, :id => server.to_param, :recordings => recording_ids, :redir_url => '/any' }
        it { should respond_with(:redirect) }
        it { should redirect_to "/any" }
      end
    end

    context "doesn't override @server" do
      let!(:other_server) { FactoryGirl.create(:bigbluebutton_server) }
      before {
        controller.instance_variable_set(:@server, other_server)
        other_server.stub(:send_publish_recordings)
      }
      before(:each) { post :unpublish_recordings, :id => server.to_param, :recordings => recording_ids }
      it { should assign_to(:server).with(other_server) }
    end
  end

  describe "#fetch_recordings" do
    before do
      # return our mocked server
      BigbluebuttonServer.stub(:find_by_param).with(server.to_param).and_return(server)
    end

    context "on success" do
      before(:each) {
        server.should_receive(:fetch_recordings).with({})
        post :fetch_recordings, :id => server.to_param
      }
      it { should respond_with(:redirect) }
      it { should redirect_to bigbluebutton_server_path(server) }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.servers.notice.fetch_recordings.success')) }
    end

    context "on failure" do
      let(:bbb_error_msg) { SecureRandom.hex(250) }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
      before(:each) {
        server.should_receive(:fetch_recordings) { raise bbb_error }
        post :fetch_recordings, :id => server.to_param
      }
      it { should respond_with(:redirect) }
      it { should redirect_to(bigbluebutton_server_path(server)) }
      it { should set_the_flash.to(bbb_error_msg[0..200]) }
    end

    context "when filtering by meetingID" do
      let(:meetings) { "m1,m2,m3" }
      it {
        server.should_receive(:fetch_recordings).with({ :meetingID => meetings })
        post :fetch_recordings, :id => server.to_param, :meetings => meetings
      }
    end

    context "when filtering by metadata" do
      let(:filters) {
        { :meta_first => "first-value", :meta_second => "second-value" }
      }
      it {
        server.should_receive(:fetch_recordings).with(filters)
        post :fetch_recordings, :id => server.to_param, :meta_first => "first-value", :meta_second => "second-value"
      }
    end

    context "doesn't override @server" do
      let!(:other_server) { FactoryGirl.create(:bigbluebutton_server) }
      before {
        controller.instance_variable_set(:@server, other_server)
        other_server.stub(:fetch_recordings)
      }
      before(:each) { post :fetch_recordings, :id => server.to_param }
      it { should assign_to(:server).with(other_server) }
    end
  end

  describe "#recordings" do
    context "basic" do
      before do
        @recording1 = FactoryGirl.create(:bigbluebutton_recording, :server => server)
        @recording2 = FactoryGirl.create(:bigbluebutton_recording, :server => server)
        FactoryGirl.create(:bigbluebutton_recording)

        # one that belongs to another server but to a room that's in the target server
        room = FactoryGirl.create(:bigbluebutton_room)
        FactoryGirl.create(:bigbluebutton_recording, :room => room)
      end
      before(:each) { get :recordings, :id => server.to_param }
      it { should respond_with(:success) }
      it { should render_template(:recordings) }
      it { should assign_to(:recordings).with([@recording1, @recording2]) }
    end

    context "doesn't override @server" do
      let!(:other_server) { FactoryGirl.create(:bigbluebutton_server) }
      before { controller.instance_variable_set(:@server, other_server) }
      before(:each) { get :recordings, :id => server.to_param }
      it { should assign_to(:server).with(other_server) }
    end

    context "doesn't override @recordings" do
      let!(:my_recordings) {
        [ FactoryGirl.create(:bigbluebutton_recording, server: server),
          FactoryGirl.create(:bigbluebutton_recording, server: server) ]
      }
      before {
        3.times { FactoryGirl.create(:bigbluebutton_recording, server: server) }
        controller.instance_variable_set(:@recordings, my_recordings)
      }
      before(:each) { get :recordings, :id => server.to_param }
      it { should assign_to(:recordings).with(my_recordings) }
    end
  end

  describe "#check" do
    before do
      # return our mocked server
      BigbluebuttonServer.stub(:find_by_param).with(server.to_param).and_return(server)
    end

    context "on success" do
      before(:each) {
        server.should_receive(:check_url).and_return('http://test-server.com/check')
        post :check, :id => server.to_param
      }
      it { should respond_with(:redirect) }
      it { should redirect_to 'http://test-server.com/check' }
    end
  end

end
