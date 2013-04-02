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

  scope "only-recordings" do
    bigbluebutton_routes :default, :only => "recordings"
  end

  bigbluebutton_routes :default,
    :scope => "custom",
    :controllers => { :servers => "custom_servers",
                      :rooms => "custom_rooms",
                      :recordings => "custom_recordings" },
    :as => "custom_name"

  root :to => "frontpage#show"

end
