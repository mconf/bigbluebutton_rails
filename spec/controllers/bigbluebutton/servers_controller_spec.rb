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
      should respond_with(:redirect)
      should redirect_to(bigbluebutton_server_path(@server))
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

  # verify all JSON responses
  context "json responses for " do

    describe "#index" do
      before do
        @server1 = Factory.create(:bigbluebutton_server)
        @server2 = Factory.create(:bigbluebutton_server)
      end
      before(:each) { get :index, :format => 'json' }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should respond_with_json([@server1, @server2].to_json) }
    end

    describe "#new" do
      before(:each) { get :new, :format => 'json' }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should respond_with_json(BigbluebuttonServer.new.to_json).ignoring_values }
    end

    describe "#show" do
      before(:each) { get :show, :id => server.to_param, :format => 'json' }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should respond_with_json(server.to_json) }
    end

    describe "#create" do
      let(:new_server) { Factory.build(:bigbluebutton_server) }

      context "on success" do
        before(:each) {
          post :create, :bigbluebutton_server => new_server.attributes, :format => 'json'
        }
        it { should respond_with(:created) }
        it { should respond_with_content_type(:json) }
        it { should respond_with_json(new_server.to_json).ignoring_attributes }
      end

      context "on failure" do
        before(:each) {
          new_server.url = nil # invalid
          post :create, :bigbluebutton_server => new_server.attributes, :format => 'json'
        }
        it { should respond_with(:unprocessable_entity) }
        it { should respond_with_content_type(:json) }
        it {
          new_server.save # should fail
          should respond_with_json(new_server.errors.to_json)
        }
      end
    end

    describe "#update" do
      let(:new_server) { Factory.build(:bigbluebutton_server) }
      before { @server = server }

      context "on success" do
        before(:each) {
          put :update, :id => @server.to_param, :bigbluebutton_server => new_server.attributes, :format => 'json'
        }
        it { should respond_with(:success) }
        it { should respond_with_content_type(:json) }
      end

      context "on failure" do
        before(:each) {
          new_server.url = nil # invalid
          put :update, :id => @server.to_param, :bigbluebutton_server => new_server.attributes, :format => 'json'
        }
        it { should respond_with(:unprocessable_entity) }
        it { should respond_with_content_type(:json) }
        it {
          new_server.save # should fail
          should respond_with_json(new_server.errors.to_json)
        }
      end
    end

    describe "#destroy" do
      before :each do
        @server = server
        delete :destroy, :id => @server.to_param, :format => 'json'
      end
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
    end

  end # json responses

end

