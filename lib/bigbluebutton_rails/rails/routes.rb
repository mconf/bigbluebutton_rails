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
    # by rails to a resource, plus two new actions for the rooms.
    #
    #    bigbluebutton_routes :default
    #
    # Some routes generated:
    #
    #   bigbluebutton_server               GET    /bigbluebutton/servers/:id(.:format)
    #                                             { :action=>"show", :controller=>"bigbluebutton/servers" }
    #                                      POST   /bigbluebutton/servers/:id(.:format)
    #                                             { :action=>"update", :controller=>"bigbluebutton/servers" }
    #   join_bigbluebutton_server_room     GET    /bigbluebutton/servers/:server_id/rooms/:id/join(.:format)
    #                                             { :action=>"join", :controller=>"bigbluebutton/rooms" }
    #   running_bigbluebutton_server_room  GET    /bigbluebutton/servers/:server_id/rooms/:id/running(.:format)
    #                                             { :action=>"running", :controller=>"bigbluebutton/rooms" }
    #
    # The routes point by default to the controllers Bigbluebutton::ServersController and Bigbluebutton::RoomsController
    # and the the routes are scoped (namespaced) with 'bigbluebutton'. You can change the namespace with:
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
    # It creates routes to the actions #show, #join, #running, #end, #invite, and #auth.
    #
    #    bigbluebutton_routes :room_matchers
    #
    # You can, for example, create routes associated with users:
    #
    #   resources :users do
    #     bigbluebutton_routes :room_matchers
    #   end
    #
    # The routes generated are:
    #
    #   user_room               GET  /users/:user_id/room/:id(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"show" }
    #   user_join_room          GET  /users/:user_id/room/:id/join(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"join" }
    #   user_join_mobile_room   GET  /users/:user_id/room/:id/invite(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"invite" }
    #   user_auth_room          POST /users/:user_id/room/:id/join(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"auth" }
    #   user_running_room       GET  /users/:user_id/room/:id/running(.:format)
    #                                { :controller=>"bigbluebutton/rooms", :action=>"running" }
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
      BigbluebuttonRails.set_controllers(options[:controllers])

      scope options_scope, :as => options_scope do
        resources :servers, :controller => BigbluebuttonRails.controllers[:servers] do
          get :activity, :on => :member
          resources :rooms, :controller => BigbluebuttonRails.controllers[:rooms] do
            collection do
              get :external
              post :external, :action => :auth
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
      end
    end

    def bigbluebutton_routes_room_matchers(*params) #:nodoc:
      # TODO This is generating helpers like "user_running_room" instead of "running_user_room"
      get 'room/:id' => "#{BigbluebuttonRails.controllers[:rooms]}#show", :as => 'room'
      get 'room/:id/join' => "#{BigbluebuttonRails.controllers[:rooms]}#join", :as => 'join_room'
      get 'room/:id/join_mobile' => "#{BigbluebuttonRails.controllers[:rooms]}#join_mobile", :as => 'join_mobile_room'
      post 'room/:id/join' => "#{BigbluebuttonRails.controllers[:rooms]}#auth", :as => 'join_room'
      get 'room/:id/running' => "#{BigbluebuttonRails.controllers[:rooms]}#running", :as => 'running_room'
      get 'room/:id/end' => "#{BigbluebuttonRails.controllers[:rooms]}#end", :as => 'end_room'
      get 'room/:id/invite' => "#{BigbluebuttonRails.controllers[:rooms]}#invite", :as => 'invite_room'
    end

  end
end

