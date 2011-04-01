RailsApp::Application.routes.draw do

  bigbluebutton_routes :default

  bigbluebutton_routes :default, :scope => "webconference"

  resources :users do
    bigbluebutton_routes :room_matchers
    resources :spaces do
      bigbluebutton_routes :room_matchers
    end
  end

end
