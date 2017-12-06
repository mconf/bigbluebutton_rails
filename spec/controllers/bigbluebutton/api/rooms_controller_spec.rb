require 'spec_helper'
require 'bigbluebutton_api'

describe Bigbluebutton::Api::RoomsController do
  render_views
  let!(:room) { FactoryGirl.create(:bigbluebutton_room) }

  before {
    @previous = BigbluebuttonRails.configuration.api_secret
    BigbluebuttonRails.configuration.api_secret = "" # all allowed
  }
  after {
    BigbluebuttonRails.configuration.api_secret = @previous
  }

  shared_examples "an authenticated API call" do

    context "when the server has a secret" do
      before {
        @previous = BigbluebuttonRails.configuration.api_secret
        BigbluebuttonRails.configuration.api_secret = "123123"
      }
      after {
        BigbluebuttonRails.configuration.api_secret = @previous
      }

      [nil, "WRONG", '', "bearer 123123"].each do |auth_header|
        context "forbids the authorization header #{auth_header.inspect}" do
          before(:each) {
            request.headers['Authorization'] = auth_header
            action
          }
          it { JSON.parse(response.body)['errors'][0]['status'].should eql('403') }
          it {
            title = JSON.parse(response.body)['errors'][0]['title']
            title.should eql(I18n.t('bigbluebutton_rails.api.errors.forbidden.title'))
          }
          it {
            detail = JSON.parse(response.body)['errors'][0]['detail']
            detail.should eql(I18n.t('bigbluebutton_rails.api.errors.forbidden.msg'))
          }
        end
      end

      context "when the valid secret is informed" do
        before(:each) {
          request.headers['Authorization'] = "Bearer 123123"
          action
        }
        it { JSON.parse(response.body)['errors'].should be_nil }
        it { JSON.parse(response.body)['data'].should_not be_nil }
      end
    end

    context "when the server has a nil secret" do
      before {
        @previous = BigbluebuttonRails.configuration.api_secret
        BigbluebuttonRails.configuration.api_secret = nil
      }
      after {
        BigbluebuttonRails.configuration.api_secret = @previous
      }

      [nil, "WRONG", '', "bearer 123123"].each do |auth_header|
        context "forbids the authorization header #{auth_header.inspect}" do
          before(:each) {
            request.headers['Authorization'] = auth_header
            action
          }
          it { JSON.parse(response.body)['errors'][0]['status'].should eql('403') }
          it {
            title = JSON.parse(response.body)['errors'][0]['title']
            title.should eql(I18n.t('bigbluebutton_rails.api.errors.forbidden.title'))
          }
          it {
            detail = JSON.parse(response.body)['errors'][0]['detail']
            detail.should eql(I18n.t('bigbluebutton_rails.api.errors.forbidden.msg'))
          }
        end
      end
    end

    context "when the server has an empty string as secret" do
      before {
        @previous = BigbluebuttonRails.configuration.api_secret
        BigbluebuttonRails.configuration.api_secret = ''
      }
      after {
        BigbluebuttonRails.configuration.api_secret = @previous
      }

      [nil, "WRONG", '', "bearer 123123"].each do |auth_header|
        context "forbids the authorization header #{auth_header.inspect}" do
          before(:each) {
            request.headers['Authorization'] = auth_header
            action
          }
          it { JSON.parse(response.body)['errors'].should be_nil }
          it { JSON.parse(response.body)['data'].should_not be_nil }
        end
      end
    end

  end

  describe "#index" do
    context "authenticates" do
      let(:action) { get :index, format: :json }
      it_should_behave_like "an authenticated API call"
    end

    context "basic" do
      before(:each) { get :index, format: :json }
      it { should respond_with(:success) }
      it { should respond_with_content_type('json') }
      it { should assign_to(:rooms).with([room]) }
      it { JSON.parse(response.body)['data'].should be_an_instance_of(Array) }
      it { JSON.parse(response.body)['data'][0]['type'].should eql('room') }
      it { JSON.parse(response.body)['data'][0]['id'].should eql(room.to_param) }
    end

    context "content" do
      let(:owner) { FactoryGirl.create(:bigbluebutton_server) } # could be any model
      before { room.update_attributes(owner: owner) }
      before(:each) { get :index, format: :json }

      it { JSON.parse(response.body)['data'][0]['attributes']['name'].should eql(room.name) }
      it { JSON.parse(response.body)['data'][0]['attributes']['private'].should eql(room.private) }
      it { JSON.parse(response.body)['data'][0]['links']['self'].should eql(room.short_path) }

      context "includes the owner in the response" do
        it { JSON.parse(response.body)['data'][0]['relationships']['owner']['data']['type'].should eql('server') }
        it { JSON.parse(response.body)['data'][0]['relationships']['owner']['data']['id'].should eql(owner.to_param) }
        it { JSON.parse(response.body)['data'][0]['relationships']['owner']['data']['attributes']['name'].should eql(owner.name) }
      end
    end

    context "empty response" do
      before { room.destroy }
      before(:each) { get :index, format: :json }
      it { JSON.parse(response.body)['data'].should be_empty }
    end

    context "filtering" do
      before { room.update_attributes(name: "La Lo", param: "lalo-1") }
      let!(:room2) { FactoryGirl.create(:bigbluebutton_room, name: "La Le", param: "lale-2") }
      let!(:room3) { FactoryGirl.create(:bigbluebutton_room, name: "Li Lo", param: "lilo") }

      context "filters by terms" do
        before(:each) { get :index, filter: { terms: 'la' }, format: :json }
        it { JSON.parse(response.body)['data'].length.should be(2) }
        it { JSON.parse(response.body)['data'][0]['attributes']['name'].should eql("La Le") }
        it { JSON.parse(response.body)['data'][1]['attributes']['name'].should eql("La Lo") }
      end

      context "orders by number of matches" do
        before(:each) { get :index, filter: { terms: 'la,1' }, format: :json }
        it { JSON.parse(response.body)['data'].length.should be(2) }
        it { JSON.parse(response.body)['data'][0]['attributes']['name'].should eql("La Lo") }
        it { JSON.parse(response.body)['data'][1]['attributes']['name'].should eql("La Le") }
      end

      context "strips the terms" do
        before(:each) { get :index, filter: { terms: ' la  ' }, format: :json }
        it { JSON.parse(response.body)['data'].length.should be(2) }
      end
    end

    context "sorting" do
      let!(:room2) { FactoryGirl.create(:bigbluebutton_room, name: room.name + "-2") }
      let!(:room3) { FactoryGirl.create(:bigbluebutton_room, name: room.name + "-3") }

      context "orders by name" do
        before(:each) { get :index, sort: 'name', format: :json }
        it { JSON.parse(response.body)['data'][0]['attributes']['name'].should eql(room.name) }
        it { JSON.parse(response.body)['data'][1]['attributes']['name'].should eql(room2.name) }
        it { JSON.parse(response.body)['data'][2]['attributes']['name'].should eql(room3.name) }
      end

      context "orders by name DESC" do
        before(:each) { get :index, sort: '-name', format: :json }
        it { JSON.parse(response.body)['data'][0]['attributes']['name'].should eql(room3.name) }
        it { JSON.parse(response.body)['data'][1]['attributes']['name'].should eql(room2.name) }
        it { JSON.parse(response.body)['data'][2]['attributes']['name'].should eql(room.name) }
      end

      context "orders by name by default" do
        before(:each) { get :index, format: :json }
        it { JSON.parse(response.body)['data'][0]['attributes']['name'].should eql(room.name) }
        it { JSON.parse(response.body)['data'][1]['attributes']['name'].should eql(room2.name) }
        it { JSON.parse(response.body)['data'][2]['attributes']['name'].should eql(room3.name) }
      end

      context "orders by activity" do
        before {
          FactoryGirl.create(:bigbluebutton_meeting, create_time: Time.now - 2.hours, room: room)
          FactoryGirl.create(:bigbluebutton_meeting, create_time: Time.now, room: room2)
          FactoryGirl.create(:bigbluebutton_meeting, create_time: Time.now - 1.hour, room: room3)
        }
        before(:each) { get :index, sort: 'activity', format: :json }
        it { JSON.parse(response.body)['data'][0]['attributes']['name'].should eql(room2.name) }
        it { JSON.parse(response.body)['data'][1]['attributes']['name'].should eql(room3.name) }
        it { JSON.parse(response.body)['data'][2]['attributes']['name'].should eql(room.name) }
      end

      context "orders by activity DESC" do
        before {
          FactoryGirl.create(:bigbluebutton_meeting, create_time: Time.now - 2.hours, room: room)
          FactoryGirl.create(:bigbluebutton_meeting, create_time: Time.now, room: room2)
          FactoryGirl.create(:bigbluebutton_meeting, create_time: Time.now - 1.hour, room: room3)
        }
        before(:each) { get :index, sort: '-activity', format: :json }
        it { JSON.parse(response.body)['data'][0]['attributes']['name'].should eql(room.name) }
        it { JSON.parse(response.body)['data'][1]['attributes']['name'].should eql(room3.name) }
        it { JSON.parse(response.body)['data'][2]['attributes']['name'].should eql(room2.name) }
      end

      context "doesn't order by anything else" do
        before {
          FactoryGirl.create(:bigbluebutton_room, attendee_key: "2")
          FactoryGirl.create(:bigbluebutton_room, attendee_key: "1")
          FactoryGirl.create(:bigbluebutton_room, attendee_key: "0")
        }
        before(:each) { get :index, sort: 'attendee_key', format: :json }
        it { JSON.parse(response.body)['data'][0]['attributes']['name'].should eql(room.name) }
        it { JSON.parse(response.body)['data'][1]['attributes']['name'].should eql(room2.name) }
        it { JSON.parse(response.body)['data'][2]['attributes']['name'].should eql(room3.name) }
      end
    end

    context "pagination" do
      context "limits to 10 by default" do
        before {
          15.times { FactoryGirl.create(:bigbluebutton_room) }
        }
        before(:each) { get :index, format: :json }
        it { JSON.parse(response.body)['data'].length.should be(10) }
      end

      context "paginates" do
        before {
          9.times { FactoryGirl.create(:bigbluebutton_room) }
          @rooms = BigbluebuttonRoom.order('name').all
        }

        context "returns the selected page" do
          before(:each) { get :index, page: { size: 2, number: 3 }, format: :json }
          it { JSON.parse(response.body)['data'].length.should be(2) }
          it { JSON.parse(response.body)['data'][0]['attributes']['name'].should eql(@rooms[4].name) }
          it { JSON.parse(response.body)['data'][1]['attributes']['name'].should eql(@rooms[5].name) }
        end

        context "returns the first page by default" do
          before(:each) { get :index, page: { size: 3 }, format: :json }
          it { JSON.parse(response.body)['data'].length.should be(3) }
          it { JSON.parse(response.body)['data'][0]['attributes']['name'].should eql(@rooms[0].name) }
          it { JSON.parse(response.body)['data'][1]['attributes']['name'].should eql(@rooms[1].name) }
          it { JSON.parse(response.body)['data'][2]['attributes']['name'].should eql(@rooms[2].name) }
        end

        context "includes the pagination links in the response" do
          before(:each) { get :index, page: { size: 2, number: 3 }, format: :json }
          it { JSON.parse(response.body)['links']['self'].should eql(request.original_url) }
          it {
            uri = URI.parse(request.original_url)
            query = Rack::Utils.parse_query(uri.query)
            query["page[number]"] = 4
            uri.query = Rack::Utils.build_query(query)
            JSON.parse(response.body)['links']['next'].should eql(uri.to_s)
          }
          it {
            uri = URI.parse(request.original_url)
            query = Rack::Utils.parse_query(uri.query)
            query["page[number]"] = 2
            uri.query = Rack::Utils.build_query(query)
            JSON.parse(response.body)['links']['prev'].should eql(uri.to_s)
          }
          it {
            uri = URI.parse(request.original_url)
            query = Rack::Utils.parse_query(uri.query)
            query["page[number]"] = 1
            uri.query = Rack::Utils.build_query(query)
            JSON.parse(response.body)['links']['first'].should eql(uri.to_s)
          }

          context "doesn't include 'prev' when in the first page" do
            before(:each) { get :index, page: { size: 2, number: 1 }, format: :json }
            it { JSON.parse(response.body)['links']['prev'].should be_nil }
          end
        end
      end
    end
  end

  describe "#running" do
    before {
      mock_server_and_api
      @api_mock.stub(:is_meeting_running?)
    }

    context "authenticates" do
      let(:action) { get :running, id: room.to_param, format: :json }
      it_should_behave_like "an authenticated API call"
    end

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
        title.should eql(I18n.t('bigbluebutton_rails.api.errors.room_not_found.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.errors.room_not_found.msg'))
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

    context "authenticates" do
      let(:action) { post :join, id: room.to_param, format: :json, name: 'User 1' }
      it_should_behave_like "an authenticated API call"
    end

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
        title.should eql(I18n.t('bigbluebutton_rails.api.errors.room_not_found.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.errors.room_not_found.msg'))
      }
    end

    context "when the room is not running" do
      before { @api_mock.stub(:is_meeting_running?).and_return(false) }
      before(:each) { post :join, id: room.to_param, format: :json, name: 'User 1' }
      it { JSON.parse(response.body)['errors'][0]['status'].should eql('400') }
      it {
        title = JSON.parse(response.body)['errors'][0]['title']
        title.should eql(I18n.t('bigbluebutton_rails.api.errors.room_not_running.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.errors.room_not_running.msg'))
      }
    end

    context "when a name is not informed" do
      before(:each) { post :join, id: room.to_param, format: :json }
      it { JSON.parse(response.body)['errors'][0]['status'].should eql('400') }
      it {
        title = JSON.parse(response.body)['errors'][0]['title']
        title.should eql(I18n.t('bigbluebutton_rails.api.errors.missing_params.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.errors.missing_params.msg'))
      }
    end

    context "when a key is not informed and the room is private" do
      before { room.update_attributes(private: true) }
      before(:each) { post :join, id: room.to_param, format: :json, name: 'User 1' }
      it { JSON.parse(response.body)['errors'][0]['status'].should eql('400') }
      it {
        title = JSON.parse(response.body)['errors'][0]['title']
        title.should eql(I18n.t('bigbluebutton_rails.api.errors.missing_params.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.errors.missing_params.msg'))
      }
    end

    context "attendee in a private room with wrong key" do
      before { room.update_attributes(private: true) }
      before(:each) { post :join, id: room.to_param, format: :json, name: 'User 1', key: 'WRONG' }
      it { JSON.parse(response.body)['errors'][0]['status'].should eql('403') }
      it {
        title = JSON.parse(response.body)['errors'][0]['title']
        title.should eql(I18n.t('bigbluebutton_rails.api.errors.invalid_key.title'))
      }
      it {
        detail = JSON.parse(response.body)['errors'][0]['detail']
        detail.should eql(I18n.t('bigbluebutton_rails.api.errors.invalid_key.msg'))
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
