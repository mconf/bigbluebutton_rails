require 'spec_helper'

describe Bigbluebutton::ServersController do
  render_views
  let(:server) { FactoryGirl.create(:bigbluebutton_server) }

  context "json responses for" do

    describe "#index" do
      before do
        @server1 = FactoryGirl.create(:bigbluebutton_server)
        @server2 = FactoryGirl.create(:bigbluebutton_server)
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
      let(:new_server) { FactoryGirl.build(:bigbluebutton_server) }

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
          should respond_with_json(new_server.errors.full_messages.to_json)
        }
      end
    end

    describe "#update" do
      let(:new_server) { FactoryGirl.build(:bigbluebutton_server) }
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
          should respond_with_json(new_server.errors.full_messages.to_json)
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

    describe "#activity" do
      let(:room1) { FactoryGirl.create(:bigbluebutton_room, :server => server) }
      let(:room2) { FactoryGirl.create(:bigbluebutton_room, :server => server) }
      before do
        # so we return our mocked server
        BigbluebuttonServer.stub!(:find_by_param).with(server.to_param).
          and_return(server)
      end

      context "on success" do
        before do
          server.should_receive(:fetch_meetings).and_return({ })
          server.should_receive(:meetings).twice.and_return([room1, room2])
          room1.should_receive(:fetch_meeting_info)
          room2.should_receive(:fetch_meeting_info)
        end
        before(:each) { get :activity, :id => server.to_param, :format => 'json' }
        it { should respond_with(:success) }
        it { should respond_with_content_type(:json) }
        it { should respond_with_json([room1, room2].to_json) }
      end

      context "on failure" do
        let(:bbb_error_msg) { SecureRandom.hex(250) }
        let(:bbb_error) { BigBlueButton::BigBlueButtonException.new(bbb_error_msg) }
        before do
          server.should_receive(:fetch_meetings).and_return({ })
          server.should_receive(:meetings).at_least(:once).and_return([room1, room2])
          room1.should_receive(:fetch_meeting_info) { raise bbb_error }
        end
        before(:each) { get :activity, :id => server.to_param, :format => 'json' }
        it { should respond_with(:error) }
        it { should respond_with_content_type(:json) }
        it { should respond_with_json([{ :message => bbb_error_msg[0..200] }, room1, room2].to_json) }
        it { should set_the_flash.to(bbb_error_msg[0..200]) }
      end

      context "ignores params[:update_list]" do
        before do
          server.should_receive(:fetch_meetings).and_return({ })
          server.should_receive(:meetings).twice.and_return([room1, room2])
          room1.should_receive(:fetch_meeting_info)
          room2.should_receive(:fetch_meeting_info)
        end
        before(:each) { get :activity, :id => server.to_param, :update_list => true, :format => 'json' }
        it { should respond_with(:success) }
        it { should respond_with_content_type(:json) }
        it { should respond_with_json([room1, room2].to_json) }
      end

    end

    describe "#rooms" do
      before do
        @room1 = FactoryGirl.create(:bigbluebutton_room, :server => server)
        @room2 = FactoryGirl.create(:bigbluebutton_room, :server => server)
      end
      before(:each) { get :rooms, :id => server.to_param, :format => 'json' }
      it { should respond_with(:success) }
      it { should respond_with_content_type(:json) }
      it { should respond_with_json([@room1, @room2].to_json) }
    end

  end
end
