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
    # bigbluebutton servers and rooms. These routes are the resourceful routes generated
    # by rails to a resource, plus the other available actions for servers and rooms.
    #
    #    bigbluebutton_routes :default
    #
    # Examples of some routes generated:
    #
    #   bigbluebutton_server               GET    /bigbluebutton/servers/:id(.:format)
    #                                             { :action=>"show", :controller=>"bigbluebutton/servers" }
    #                                      POST   /bigbluebutton/servers/:id(.:format)
    #                                             { :action=>"update", :controller=>"bigbluebutton/servers" }
    #   join_bigbluebutton_room            GET    /bigbluebutton/rooms/:id/join(.:format)
    #                                             { :action=>"join", :controller=>"bigbluebutton/rooms" }
    #   running_bigbluebutton_room         GET    /bigbluebutton/rooms/:id/running(.:format)
    #                                             { :action=>"running", :controller=>"bigbluebutton/rooms" }
    #
    # The routes point by default to the controllers Bigbluebutton::ServersController and Bigbluebutton::RoomsController
    # and they are scoped (namespaced) with 'bigbluebutton'. You can change the namespace with:
    #
    #    bigbluebutton_routes :default, :scope => "webconference"
    #
    # You can also change the controllers with:
    #
    #    bigbluebutton_routes :default, :controllers { :servers => "custom_servers", :rooms => "custom_rooms" }
    #
    # ==== Room matchers
    #
    # Generates matchers to access a room from a different url or inside another resource.
    # Rooms can belong to users, communities or any other type of "entity" in an aplication.
    # This helper creates routes to the all the actions available in Bigbluebutton::RoomsController.
    #
    #    bigbluebutton_routes :room_matchers
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
    #   user_join_room          GET  /users/:user_id/room/:id/join(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"join" }
    #   user_end_room           GET  /users/:user_id/room/:id/end(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"end" }
    #   user_invite_room        GET  /users/:user_id/room/:id/invite(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"invite" }
    #
    def bigbluebutton_routes(*params)
      options = params.extract_options!
      send("bigbluebutton_routes_#{params[0].to_s}", options)
    end

    protected

    def bigbluebutton_routes_default(*params) #:nodoc:
      options = params.extract_options!
      options_scope = options.has_key?(:scope) ? options[:scope] : BigbluebuttonRails.routing_scope
      options_as = options.has_key?(:as) ? options[:as] : options_scope
      options_only = options.has_key?(:only) ? options[:only] : nil
      BigbluebuttonRails.set_controllers(options[:controllers])

      scope options_scope, :as => options_as do
        if options_only.nil?
          add_routes_for_servers
          add_routes_for_rooms
        else
          options_only.include?('servers') ? add_routes_for_servers : add_routes_for_rooms
        end
      end
    end

    def bigbluebutton_routes_room_matchers(*params) #:nodoc:
      add_routes_for_rooms
    end

    def add_routes_for_rooms
      resources :rooms, :controller => BigbluebuttonRails.controllers[:rooms] do
        collection do
          get :external
          post :external, :action => :external_auth
        end
        member do
          get :join
          get :running
          get :end
          get :invite
          get :join_mobile
          post :join, :action => :auth
        end
      end
    end

    def add_routes_for_servers
      resources :servers, :controller => BigbluebuttonRails.controllers[:servers] do
        get :activity, :on => :member
        get :rooms, :on => :member
      end
    end

  end
end
