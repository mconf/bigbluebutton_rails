require 'spec_helper'
require 'bigbluebutton_api'

describe Bigbluebutton::Api::RoomsController do
  render_views
  let!(:room) { FactoryGirl.create(:bigbluebutton_room) }

  describe "#running" do
    before {
      mock_server_and_api
      @api_mock.stub(:is_meeting_running?)
    }

    context "basic" do
      before(:each) { get :running, id: room.to_param, format: :json }
      it { should respond_with(:success) }
      it { should respond_with_content_type('json') }
      it { should assign_to(:room).with(room) }
      it { JSON.parse(response.body)['data']['type'].should eql('room') }
      it { JSON.parse(response.body)['data']['id'].should eql(room.to_param) }
      it { room.request_headers["x-forwarded-for"].should eql(request.remote_ip) }
    end

    context "room is running" do
      before { @api_mock.stub(:is_meeting_running?).and_return(true) }
      before(:each) { get :running, id: room.to_param, format: :json }
      it { JSON.parse(response.body)['data']['attributes']['running'].should be(true) }
    end

    context "room is running" do
      before { @api_mock.should_receive(:is_meeting_running?).and_return(false) }
      before(:each) { get :running, id: room.to_param, format: :json }
      it { JSON.parse(response.body)['data']['attributes']['running'].should be(false) }
    end

    context "when the room is not found" do
      before { BigbluebuttonRoom.stub(:find_by).and_return(nil) }
      before(:each) { post :running, id: room.to_param + '-2', format: :json }
      it { JSON.parse(response.body)['errors'][0]['status'].should eql('404') }
      it {
        title = JSON.parse(response.body)['errors'][0]['title']
        title.should eql(I18n.t('bigbluebutton_rails.api.rooms.room_not_found.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.rooms.room_not_found.msg'))
      }
    end
  end

  describe "#join" do
    let(:expected_url) { 'https://fake-url.no/join?anything=1' }
    before {
      mock_server_and_api
      @api_mock.stub(:is_meeting_running?).and_return(true)
      @api_mock.stub(:join_meeting_url).and_return(expected_url)
    }

    context "basic" do
      before { room.update_attributes(private: false) }
      before(:each) { post :join, id: room.to_param, format: :json, name: 'User 1' }
      it { should respond_with(:success) }
      it { should respond_with_content_type('json') }
      it { should assign_to(:room).with(room) }
      it { should assign_to(:url).with(expected_url) }
      it { JSON.parse(response.body)['data']['type'].should eql('join-url') }
      it { JSON.parse(response.body)['data']['id'].should eql(expected_url) }
      it { room.request_headers["x-forwarded-for"].should eql(request.remote_ip) }
    end

    context "generates the correct join url" do
      let(:expected_url) { 'https://another-fake-url.no/join?anything=1' }

      context "attendee in a public room" do
        before {
          room.should_receive(:parameterized_join_url).with('User 1', :attendee, nil, {}).and_return(expected_url)
        }
        before(:each) { post :join, id: room.to_param, format: :json, name: 'User 1' }
        it { JSON.parse(response.body)['data']['id'].should eql(expected_url) }
      end

      context "attendee in a private room" do
        before {
          room.update_attributes(private: true)
          room.should_receive(:parameterized_join_url).with('User 1', :attendee, nil, {}).and_return(expected_url)
        }
        before(:each) { post :join, id: room.to_param, format: :json, name: 'User 1', key: room.attendee_key }
        it { JSON.parse(response.body)['data']['id'].should eql(expected_url) }
      end

      context "moderator in a private room" do
        before {
          room.update_attributes(private: true)
          room.should_receive(:parameterized_join_url).with('User 1', :moderator, nil, {}).and_return(expected_url)
        }
        before(:each) { post :join, id: room.to_param, format: :json, name: 'User 1', key: room.moderator_key }
        it { JSON.parse(response.body)['data']['id'].should eql(expected_url) }
      end

      context "with metadata" do
        let(:expected_meta) {
          { 'userdata-param-1' => 1, 'userdata-param_2' => 'string-2' }
        }
        before {
          room.should_receive(:parameterized_join_url).with('User 1', :attendee, nil, expected_meta).and_return(expected_url)
        }
        before(:each) {
          post :join, id: room.to_param, format: :json, name: 'User 1', key: room.moderator_key,
               'meta-param-1': 1, meta_param_2: 'string-2'
        }
        it { JSON.parse(response.body)['data']['id'].should eql(expected_url) }
      end
    end

    context "when the room is not found" do
      before { BigbluebuttonRoom.stub(:find_by).and_return(nil) }
      before(:each) { post :join, id: room.to_param + '-2', format: :json, name: 'User 1' }
      it { JSON.parse(response.body)['errors'][0]['status'].should eql('404') }
      it {
        title = JSON.parse(response.body)['errors'][0]['title']
        title.should eql(I18n.t('bigbluebutton_rails.api.rooms.room_not_found.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.rooms.room_not_found.msg'))
      }
    end

    context "when the room is not running" do
      before { @api_mock.stub(:is_meeting_running?).and_return(false) }
      before(:each) { post :join, id: room.to_param, format: :json, name: 'User 1' }
      it { JSON.parse(response.body)['errors'][0]['status'].should eql('400') }
      it {
        title = JSON.parse(response.body)['errors'][0]['title']
        title.should eql(I18n.t('bigbluebutton_rails.api.rooms.room_not_running.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.rooms.room_not_running.msg'))
      }
    end

    context "when a name is not informed" do
      before(:each) { post :join, id: room.to_param, format: :json }
      it { JSON.parse(response.body)['errors'][0]['status'].should eql('400') }
      it {
        title = JSON.parse(response.body)['errors'][0]['title']
        title.should eql(I18n.t('bigbluebutton_rails.api.rooms.missing_params.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.rooms.missing_params.msg'))
      }
    end

    context "when a key is not informed and the room is private" do
      before { room.update_attributes(private: true) }
      before(:each) { post :join, id: room.to_param, format: :json, name: 'User 1' }
      it { JSON.parse(response.body)['errors'][0]['status'].should eql('400') }
      it {
        title = JSON.parse(response.body)['errors'][0]['title']
        title.should eql(I18n.t('bigbluebutton_rails.api.rooms.missing_params.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.rooms.missing_params.msg'))
      }
    end

    context "attendee in a private room with wrong key" do
      before { room.update_attributes(private: true) }
      before(:each) { post :join, id: room.to_param, format: :json, name: 'User 1', key: 'WRONG' }
      it { JSON.parse(response.body)['errors'][0]['status'].should eql('403') }
      it {
        title = JSON.parse(response.body)['errors'][0]['title']
        title.should eql(I18n.t('bigbluebutton_rails.api.rooms.invalid_key.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.rooms.invalid_key.msg'))
      }
    end

    context "when guest support is on" do
      let(:expected_url) { 'https://another-fake-url.no/join?anything=1' }
      before {
        @guest_support = BigbluebuttonRails.configuration.guest_support
        BigbluebuttonRails.configuration.guest_support = true
      }
      after {
        BigbluebuttonRails.configuration.guest_support = @guest_support
      }

      before {
        room.should_receive(:parameterized_join_url).with('User 1', :guest, nil, {}).and_return(expected_url)
      }
      before(:each) { post :join, id: room.to_param, format: :json, name: 'User 1' }
      it { JSON.parse(response.body)['data']['id'].should eql(expected_url) }
    end
  end
end
