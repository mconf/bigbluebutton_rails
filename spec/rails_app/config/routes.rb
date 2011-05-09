RailsApp::Application.routes.draw do

  bigbluebutton_routes :default

  bigbluebutton_routes :default, :scope => "webconference"

  resources :users do
    bigbluebutton_routes :room_matchers
    resources :spaces do
      bigbluebutton_routes :room_matchers
    end
  end

  # note: controllers modified here will be used in the routes added after this (if any)
  bigbluebutton_routes :default, :scope => "custom", :controllers => { :servers => 'custom_servers', :rooms => 'custom_rooms' }

end
