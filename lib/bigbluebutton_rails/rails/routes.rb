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
    # The controllers used will always be bigbluebutton/servers and bigbluebutton/rooms,
    # but you can change the url using the scope option:
    #
    #    bigbluebutton_routes :default, :scope => "webconference"
    #
    # This will generate routes such as:
    #
    #   webconference_server               GET    /webconference/servers/:id(.:format)
    #                                             { :action=>"show", :controller=>"bigbluebutton/servers" }
    #                                      POST   /webconference/servers/:id(.:format)
    #                                             { :action=>"update", :controller=>"bigbluebutton/servers" }
    #   join_webconference_server_room     GET    /webconference/servers/:server_id/rooms/:id/join(.:format)
    #                                             { :action=>"join", :controller=>"bigbluebutton/rooms" }
    #   running_webconference_server_room  GET    /webconference/servers/:server_id/rooms/:id/running(.:format)
    #                                             { :action=>"running", :controller=>"bigbluebutton/rooms" }
    #
    # ==== Room matchers
    #
    # Generates matchers to access a room from a different url or inside another resource.
    # It creates routes to the actions #show, #join, #running, and #end.
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
    #   user_room          GET  /users/:user_id/room/:id(.:format)
    #                           { :controller=>"bigbluebutton/rooms", :action=>"show" }
    #   user_join_room     GET  /users/:user_id/room/:id/join(.:format)
    #                           { :controller=>"bigbluebutton/rooms", :action=>"join" }
    #   user_running_room  GET  /users/:user_id/room/:id/running(.:format)
    #                           { :controller=>"bigbluebutton/rooms", :action=>"running" }
    #   user_end_room      GET  /users/:user_id/room/:id/end(.:format)
    #                           { :controller=>"bigbluebutton/rooms", :action=>"end" }
    #
    def bigbluebutton_routes(*params)
      options = params.extract_options!
      send("bigbluebutton_routes_#{params[0].to_s}", options)
    end

    protected

    def bigbluebutton_routes_default(*params) #:nodoc:
      options = params.extract_options!
      options_scope = options.has_key?(:scope) ? options[:scope] : 'bigbluebutton'

      scope options_scope, :as => options_scope do
        resources :servers, :controller => 'bigbluebutton/servers' do
          resources :rooms, :controller => 'bigbluebutton/rooms' do
            get :join, :on => :member
            get :running, :on => :member
            get :end, :on => :member
          end
        end
      end
    end

    def bigbluebutton_routes_room_matchers(*params) #:nodoc:
      get 'room/:id' => 'bigbluebutton/rooms#show', :as => 'room'
      get 'room/:id/join' => 'bigbluebutton/rooms#join', :as => 'join_room'
      get 'room/:id/running' => 'bigbluebutton/rooms#running', :as => 'running_room'
      get 'room/:id/end' => 'bigbluebutton/rooms#end', :as => 'end_room'
    end

  end
end

