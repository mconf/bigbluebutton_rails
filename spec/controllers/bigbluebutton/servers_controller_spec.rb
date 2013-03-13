require 'spec_helper'

describe Bigbluebutton::ServersController do
  render_views
  let(:server) { FactoryGirl.create(:bigbluebutton_server) }

  describe "#index" do
    before { 3.times { FactoryGirl.create(:bigbluebutton_server) } }
    before(:each) { get :index }
    it { should respond_with(:success) }
    it { should assign_to(:servers).with(BigbluebuttonServer.all) }
    it { should render_template(:index) }
  end

  describe "#show" do
    before(:each) { get :show, :id => server.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
    it { should render_template(:show) }
  end

  describe "#new" do
    before(:each) { get :new }
    it { should respond_with(:success) }
    it { should assign_to(:server).with_kind_of(BigbluebuttonServer) }
    it { should render_template(:new) }
  end

  describe "#edit" do
    before(:each) { get :edit, :id => server.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
    it { should render_template(:edit) }
  end

  describe "#create" do
    before :each do
      expect {
        post :create, :bigbluebutton_server => FactoryGirl.attributes_for(:bigbluebutton_server)
      }.to change{ BigbluebuttonServer.count }.by(1)
    end
    it {
      should respond_with(:redirect)
      should redirect_to(bigbluebutton_server_path(BigbluebuttonServer.last))
    }
    it { should set_the_flash.to(I18n.t('bigbluebutton_rails.servers.notice.create.success')) }
  end

  describe "#update" do
    let(:new_server) { FactoryGirl.build(:bigbluebutton_server) }
    before { @server = server } # need this to trigger let(:server) and actually create the object

    context "on success" do
      before :each do
        expect {
          put :update, :id => @server.to_param, :bigbluebutton_server => new_server.attributes
        }.not_to change{ BigbluebuttonServer.count }
      end
      it {
        saved = BigbluebuttonServer.find(@server)
        should respond_with(:redirect)
        should redirect_to(bigbluebutton_server_path(saved))
      }
      it {
        saved = BigbluebuttonServer.find(@server)
        saved.should have_same_attributes_as(new_server)
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.servers.notice.update.success')) }
    end

    context "on failure" do
      before :each do
        new_server.url = nil # invalid
        put :update, :id => @server.to_param, :bigbluebutton_server => new_server.attributes
      end
      it { should render_template(:edit) }
      it { should assign_to(:server).with(@server) }
    end
 end


  describe "#destroy" do
    before :each do
      @server = server
      expect {
        delete :destroy, :id => @server.to_param
      }.to change{ BigbluebuttonServer.count }.by(-1)
    end
    it {
      should respond_with(:redirect)
      should redirect_to(bigbluebutton_servers_path)
    }
  end

  describe "#activity" do
    let(:room1) { FactoryGirl.create(:bigbluebutton_room, :server => server) }
    let(:room2) { FactoryGirl.create(:bigbluebutton_room, :server => server) }
    before do
      # return our mocked server
      BigbluebuttonServer.stub!(:find_by_param).with(server.to_param).
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
          it { should render_template(:activity_list) }
        end
        context "and :format = 'html'" do
          before(:each) { get :activity, :id => server.to_param, :update_list => true, :format => "html" }
          it { should render_template(:activity_list) }
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

  end # #activity

  describe "#rooms" do
    before do
      @room1 = FactoryGirl.create(:bigbluebutton_room, :server => server)
      @room2 = FactoryGirl.create(:bigbluebutton_room, :server => server)
      FactoryGirl.create(:bigbluebutton_room)
    end
    before(:each) { get :rooms, :id => server.to_param }
    it { should respond_with(:success) }
    it { should render_template(:rooms) }
    it { should assign_to(:rooms).with([@room1, @room2]) }
  end

  describe "#publish_recordings" do
    let(:recording_ids) { "id1,id2,id3" }
    before do
      # return our mocked server
      BigbluebuttonServer.stub!(:find_by_param).with(server.to_param).and_return(server)
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
  end

  describe "#unpublish_recordings" do
    let(:recording_ids) { "id1,id2,id3" }
    before do
      # return our mocked server
      BigbluebuttonServer.stub!(:find_by_param).with(server.to_param).and_return(server)
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
  end

  describe "#fetch_recordings" do
    before do
      # return our mocked server
      BigbluebuttonServer.stub!(:find_by_param).with(server.to_param).and_return(server)
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
  end

  describe "#recordings" do
    before do
      @recording1 = FactoryGirl.create(:bigbluebutton_recording, :server => server)
      @recording2 = FactoryGirl.create(:bigbluebutton_recording, :server => server)
      FactoryGirl.create(:bigbluebutton_recording)

      # one that belongs to another server but to a room that's in the target server
      room = FactoryGirl.create(:bigbluebutton_room, :server => server)
      FactoryGirl.create(:bigbluebutton_recording, :room => room)
    end
    before(:each) { get :recordings, :id => server.to_param }
    it { should respond_with(:success) }
    it { should render_template(:recordings) }
    it { should assign_to(:recordings).with([@recording1, @recording2]) }
  end

end
