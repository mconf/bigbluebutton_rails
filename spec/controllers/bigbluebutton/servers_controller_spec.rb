require 'spec_helper'

describe Bigbluebutton::ServersController do
  render_views
  let(:server) { Factory.create(:bigbluebutton_server) }

  describe "#index" do
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
        post :create, :bigbluebutton_server => Factory.attributes_for(:bigbluebutton_server)
      }.to change{ BigbluebuttonServer.count }.by(1)
    end
    it {
      should respond_with(:redirect)
      should redirect_to(bigbluebutton_server_path(BigbluebuttonServer.last))
    }
    it { should set_the_flash.to(I18n.t('bigbluebutton_rails.servers.notice.create.success')) }
  end

  describe "#update" do
    let(:new_server) { Factory.build(:bigbluebutton_server) }
    before :each do
      @server = server
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
    let(:room1) { Factory.create(:bigbluebutton_room, :server => server) }
    let(:room2) { Factory.create(:bigbluebutton_room, :server => server) }
    before do
      # so we return our mocked server
      BigbluebuttonServer.stub!(:find_by_param).with(server.to_param).
        and_return(server)
    end

    context "standard behaviour" do

      before do
        # we have to mock calls that trigger BBB API calls
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
        before(:each) { get :activity, :id => server.to_param, :update_list => true }
        it { should render_template(:activity_list) }
      end

    end

   context "exception handling" do
      let(:bbb_error_msg) { "err msg" }
      let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }

      context "at fetch_meetings" do
        before { server.should_receive(:fetch_meetings) { raise bbb_error } }
        before(:each) { get :activity, :id => server.to_param }
        it { should set_the_flash.to(bbb_error_msg) }
      end

      context "at fetch_meeting_info" do
        before do
          server.should_receive(:fetch_meetings).and_return({ })
          server.should_receive(:meetings).at_least(:once).and_return([room1, room2])
          room1.should_receive(:fetch_meeting_info) { raise bbb_error }
        end
        before(:each) { get :activity, :id => server.to_param }
        it { should set_the_flash.to(bbb_error_msg) }
      end
    end

  end

end

