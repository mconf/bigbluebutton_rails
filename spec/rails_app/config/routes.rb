RailsApp::Application.routes.draw do

  bigbluebutton_routes :default

  bigbluebutton_routes :default, :scope => "webconference"

  resources :users do
    bigbluebutton_routes :room_matchers
    resources :spaces do
      bigbluebutton_routes :room_matchers
    end
  end

  scope "only-servers" do
    bigbluebutton_routes :default, :only => "servers"
  end

  scope "only-rooms" do
    bigbluebutton_routes :default, :only => "rooms"
  end

  bigbluebutton_routes :default,
    :scope => "custom",
    :controllers => { :servers => "custom_servers", :rooms => "custom_rooms" },
    :as => "custom_name"
end
