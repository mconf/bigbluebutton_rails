require 'spec_helper'

describe ActionController do
  include Shoulda::Matchers::ActionController

  describe "routing" do

    # custom controllers - servers
    it {
      {:get => "/custom/servers"}.
      should route_to(:controller => "custom_servers", :action => "index")
    }
    it {
      {:post => "/custom/servers"}.
      should route_to(:controller => "custom_servers", :action => "create")
    }
    it {
      {:get => "/custom/servers/new"}.
      should route_to(:controller => "custom_servers", :action => "new")
    }
    it {
      {:get => "/custom/servers/1/edit"}.
      should route_to(:controller => "custom_servers", :action => "edit", :id => "1")
    }
    it {
      {:get => "/custom/servers/1"}.
      should route_to(:controller => "custom_servers", :action => "show", :id => "1")
    }
    it {
      {:put => "/custom/servers/1"}.
      should route_to(:controller => "custom_servers", :action => "update", :id => "1")
    }
    it {
      {:delete => "/custom/servers/1"}.
      should route_to(:controller => "custom_servers", :action => "destroy", :id => "1")
    }
    it {
      {:get => "/custom/servers/1/activity"}.
      should route_to(:controller => "custom_servers", :action => "activity", :id => "1")
    }
    it {
      {:get => "/custom/servers/1/recordings"}.
      should route_to(:controller => "custom_servers", :action => "recordings", :id => "1")
    }
    it {
      {:post => "/custom/servers/1/publish_recordings"}.
      should route_to(:controller => "custom_servers", :action => "publish_recordings", :id => "1")
    }
    it {
      {:post => "/custom/servers/1/unpublish_recordings"}.
      should route_to(:controller => "custom_servers", :action => "unpublish_recordings", :id => "1")
    }
    it {
      {:post => "/custom/servers/1/fetch_recordings"}.
      should route_to(:controller => "custom_servers", :action => "fetch_recordings", :id => "1")
    }

    # custom controllers - rooms
    it {
      {:get => "/custom/rooms"}.
      should route_to(:controller => "custom_rooms", :action => "index")
    }
    it {
      {:get => "/custom/rooms/new"}.
      should route_to(:controller => "custom_rooms", :action => "new")
    }
    it {
      {:get => "/custom/rooms/1"}.
      should route_to(:controller => "custom_rooms", :action => "show", :id => "1")
    }
    it {
      {:get => "/custom/rooms/1/edit"}.
      should route_to(:controller => "custom_rooms", :action => "edit", :id => "1")
    }
    it {
      {:put => "/custom/rooms/1"}.
      should route_to(:controller => "custom_rooms", :action => "update", :id => "1")
    }
    it {
      {:delete => "/custom/rooms/1"}.
      should route_to(:controller => "custom_rooms", :action => "destroy", :id => "1")
    }
    it {
      {:get => "/custom/rooms/external"}.
      should route_to(:controller => "custom_rooms", :action => "external")
    }
    it {
      {:post => "/custom/rooms/external"}.
      should route_to(:controller => "custom_rooms", :action => "external_auth")
    }
    it {
      {:get => "/custom/rooms/1/join"}.
      should route_to(:controller => "custom_rooms", :action => "join", :id => "1")
    }
    it {
      {:get => "/custom/rooms/1/join_mobile"}.
      should route_to(:controller => "custom_rooms", :action => "join_mobile" ,:id => "1")
    }
    it {
      {:get => "/custom/rooms/1/running"}.
      should route_to(:controller => "custom_rooms", :action => "running", :id => "1")
    }
    it {
      {:get => "/custom/rooms/1/end"}.
      should route_to(:controller => "custom_rooms", :action => "end", :id => "1")
    }
    it {
      {:get => "/custom/rooms/1/invite"}.
      should route_to(:controller => "custom_rooms", :action => "invite", :id => "1")
    }
    it {
      {:post => "/custom/rooms/1/join"}.
      should route_to(:controller => "custom_rooms", :action => "auth", :id => "1")
    }
    it {
      {:post => "/custom/rooms/1/fetch_recordings"}.
      should route_to(:controller => "custom_rooms", :action => "fetch_recordings", :id => "1")
    }
    it {
      {:get => "/custom/rooms/1/recordings"}.
      should route_to(:controller => "custom_rooms", :action => "recordings", :id => "1")
    }

    # custom controllers - recordings
    it {
      {:get => "/custom/recordings"}.
      should route_to(:controller => "custom_recordings", :action => "index")
    }
    it {
      {:get => "/custom/recordings/1/edit"}.
      should route_to(:controller => "custom_recordings", :action => "edit", :id => "1")
    }
    it {
      {:get => "/custom/recordings/1"}.
      should route_to(:controller => "custom_recordings", :action => "show", :id => "1")
    }
    it {
      {:put => "/custom/recordings/1"}.
      should route_to(:controller => "custom_recordings", :action => "update", :id => "1")
    }
    it {
      {:delete => "/custom/recordings/1"}.
      should route_to(:controller => "custom_recordings", :action => "destroy", :id => "1")
    }

    context "custom named route helpers" do
      let(:server) { FactoryGirl.create(:bigbluebutton_server) }
      let(:room) { FactoryGirl.create(:bigbluebutton_room) }
      let(:recording) { FactoryGirl.create(:bigbluebutton_recording) }

      it { custom_name_servers_path.should == "/custom/servers" }
      it { new_custom_name_server_path.should == "/custom/servers/new" }
      it { edit_custom_name_server_path(server).should == "/custom/servers/#{server.to_param}/edit" }
      it { custom_name_server_path(server).should == "/custom/servers/#{server.to_param}" }
      it { activity_custom_name_server_path(server).should == "/custom/servers/#{server.to_param}/activity" }
      it { fetch_recordings_custom_name_server_path(server).should == "/custom/servers/#{server.to_param}/fetch_recordings" }
      it { recordings_custom_name_server_path(server).should == "/custom/servers/#{server.to_param}/recordings" }
      it { publish_recordings_custom_name_server_path(server).should == "/custom/servers/#{server.to_param}/publish_recordings" }
      it { unpublish_recordings_custom_name_server_path(server).should == "/custom/servers/#{server.to_param}/unpublish_recordings" }

      it { custom_name_rooms_path.should == "/custom/rooms" }
      it { new_custom_name_room_path.should == "/custom/rooms/new" }
      it { edit_custom_name_room_path(room).should == "/custom/rooms/#{room.to_param}/edit" }
      it { custom_name_room_path(room).should == "/custom/rooms/#{room.to_param}" }
      it { external_custom_name_rooms_path.should == "/custom/rooms/external" }
      it { join_custom_name_room_path(room).should == "/custom/rooms/#{room.to_param}/join" }
      it { join_mobile_custom_name_room_path(room).should == "/custom/rooms/#{room.to_param}/join_mobile" }
      it { end_custom_name_room_path(room).should == "/custom/rooms/#{room.to_param}/end" }
      it { invite_custom_name_room_path(room).should == "/custom/rooms/#{room.to_param}/invite" }
      it { fetch_recordings_custom_name_room_path(room).should == "/custom/rooms/#{room.to_param}/fetch_recordings" }
      it { recordings_custom_name_room_path(room).should == "/custom/rooms/#{room.to_param}/recordings" }

      it { custom_name_recordings_path.should == "/custom/recordings" }
      it { edit_custom_name_recording_path(recording).should == "/custom/recordings/#{recording.to_param}/edit" }
      it { custom_name_recording_path(recording).should == "/custom/recordings/#{recording.to_param}" }
    end

  end

end
