module ActionDispatch::Routing

  class Mapper

    # Helper to define routes for bigbluebutton_rails.
    #
    # ==== Avaliable options
    #
    #   bigbluebutton_routes :default
    #   bigbluebutton_routes :room_matchers
    #
    # ==== Default routes
    #
    # Passing the option :default, it will generate the default routes to access
    # servers, rooms and recordings. The routes generated are the CRUD routes generated
    # by rails to a resource, plus the other available actions for servers and rooms.
    #
    #   bigbluebutton_routes :default
    #
    # Examples of some routes generated:
    #
    #   bigbluebutton_server               GET    /bigbluebutton/servers/:id(.:format)
    #                                             { :action=>"show", :controller=>"bigbluebutton/servers" }
    #                                      POST   /bigbluebutton/servers/:id(.:format)
    #                                             { :action=>"update", :controller=>"bigbluebutton/servers" }
    #
    #   join_bigbluebutton_room            GET    /bigbluebutton/rooms/:id/join(.:format)
    #                                             { :action=>"join", :controller=>"bigbluebutton/rooms" }
    #
    #   running_bigbluebutton_room         GET    /bigbluebutton/rooms/:id/running(.:format)
    #                                             { :action=>"running", :controller=>"bigbluebutton/rooms" }
    #
    #   play_bigbluebutton_recording       GET    /bigbluebutton/recordings/:id/play(.:format)
    #                                             { :action=>"play", :controller=>"bigbluebutton/recordings" }
    #
    # The routes point by default to the controllers provided by this gem
    # and they are scoped (namespaced) with 'bigbluebutton'. You can change the namespace with:
    #
    #   bigbluebutton_routes :default, :scope => "webconference"
    #
    # You can also change the controllers with:
    #
    #   bigbluebutton_routes :default,
    #                        :controllers => { :servers => "custom_servers",
    #                                          :rooms => "custom_rooms",
    #                                          :recordings => "custom_recordings",
    #                                          :playback_types => "custom_playback_types }
    #
    # ==== Room matchers
    #
    # Generates matchers to access a room from a different url or inside another resource.
    # Rooms can belong to users, communities or any other type of "entity" in an aplication.
    # This helper creates routes to the all the actions available in Bigbluebutton::RoomsController.
    #
    #   bigbluebutton_routes :room_matchers
    #
    # You can, for example, create routes associated with users:
    #
    #   resources :users do
    #     bigbluebutton_routes :room_matchers
    #   end
    #
    # Examples of some routes generated:
    #
    #   user_room               GET  /users/:user_id/room/:id(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"show" }
    #
    #   user_join_room          GET  /users/:user_id/room/:id/join(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"join" }
    #
    #   user_end_room           GET  /users/:user_id/room/:id/end(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"end" }
    #
    #   user_invite_room        GET  /users/:user_id/room/:id/invite(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"invite" }
    #
    def bigbluebutton_routes(*params)
      options = params.extract_options!
      send("bigbluebutton_routes_#{params[0].to_s}", options)
    end

    def bigbluebutton_api_routes(api_scope='/api/conference')
      scope api_scope do
        resources :rooms, only: [] do
          collection do
            get :index, to: 'bigbluebutton/api/rooms#index'
          end
          member do
            get :running, to: 'bigbluebutton/api/rooms#running'
            post :join, to: 'bigbluebutton/api/rooms#join'
          end
        end
      end
    end

    protected

    def bigbluebutton_routes_default(*params) #:nodoc:
      options = params.extract_options!
      options_scope = options.has_key?(:scope) ? options[:scope] : BigbluebuttonRails.configuration.routing_scope
      options_as = options.has_key?(:as) ? options[:as] : options_scope
      options_only = options.has_key?(:only) ? options[:only] : ["servers", "rooms", "recordings", "playback_types", "meetings"]
      BigbluebuttonRails.configuration.set_controllers(options[:controllers])

      scope options_scope, :as => options_as do
        add_routes_for_servers if options_only.include?("servers")
        add_routes_for_rooms if options_only.include?("rooms")
        add_routes_for_recordings if options_only.include?("recordings")
        add_routes_for_playback_types if options_only.include?("playback_types")
        add_routes_for_meetings if options_only.include?("meetings")
      end
    end

    def bigbluebutton_routes_room_matchers(*params) #:nodoc:
      add_routes_for_rooms
    end

    def add_routes_for_rooms #:nodoc:
      resources :rooms, :controller => BigbluebuttonRails.configuration.controllers[:rooms] do
        member do
          get :join
          get :running
          get :end
          get :invite
          get :join_mobile
          post :join
          post :fetch_recordings
          get :recordings
          post :generate_dial_number
        end
      end
    end

    def add_routes_for_servers #:nodoc:
      resources :servers, :controller => BigbluebuttonRails.configuration.controllers[:servers] do
        member do
          get :activity
          get :rooms
          get :recordings
          get :check
          post :publish_recordings
          post :unpublish_recordings
          post :fetch_recordings
        end
      end
    end

    def add_routes_for_recordings #:nodoc:
      resources :recordings, :except => [:new, :create],
                             :controller => BigbluebuttonRails.configuration.controllers[:recordings] do
        member do
          get :play
          post :publish
          post :unpublish
        end
      end
    end

    def add_routes_for_playback_types #:nodoc:
      resources :playback_types, :only => [:update],
                                 :controller => BigbluebuttonRails.configuration.controllers[:playback_types]
    end

    def add_routes_for_meetings #:nodoc:
      resources :meetings, :controller => 'bigbluebutton/meetings', :only => [:destroy]
    end
  end
end
