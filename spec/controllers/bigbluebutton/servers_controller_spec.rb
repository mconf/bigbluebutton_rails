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
    it { should respond_with(:redirect) }
    it { should redirect_to(bigbluebutton_server_path(BigbluebuttonServer.last)) }
  end

  it "#update"
  it "#destroy"

end

