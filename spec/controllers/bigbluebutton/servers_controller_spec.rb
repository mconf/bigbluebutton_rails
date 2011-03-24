require 'spec_helper'

describe Bigbluebutton::ServersController do

  render_views
  let(:server) { Factory.create(:bigbluebutton_server) }

  describe "#index" do
    before(:each) { get :index }
    it { should respond_with(:success) }
    it { should assign_to(:servers).with(BigbluebuttonServer.all) }
  end

  describe "#show" do
    before(:each) { get :show, :id => server.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
  end

  describe "#new" do
    before(:each) { get :new }
    it { should respond_with(:success) }
    it { should assign_to(:server).with_kind_of(BigbluebuttonServer) }
  end

  describe "#edit" do
    before(:each) { get :edit, :id => server.to_param }
    it { should respond_with(:success) }
    it { should assign_to(:server).with(server) }
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
    it { should set_the_flash.to(I18n.t('bigbluebutton_rails.servers.notice.successfully_created')) }
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
      should respond_with(:redirect)
      should redirect_to(bigbluebutton_server_path(@server))
    }
    it {
      saved = BigbluebuttonServer.find(@server)
      saved.should have_same_attributes_as(new_server)
    }
    it { should set_the_flash.to(I18n.t('bigbluebutton_rails.servers.notice.successfully_updated')) }
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

end

