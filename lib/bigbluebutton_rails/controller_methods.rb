module BigbluebuttonRails

  # Module that is automatically included into all controllers.
  module ControllerMethods

    def self.included(base)
      base.class_eval do

        # Method used to acquire the user for which the BigBlueButton actions are being
        # called (e.g. the user creating or joining the room).
        # Defaults to the user currently logged in, using the method current_user.
        # If your application has no method current_user or if you want
        # to change the behavior of this method, just redefine it in your
        # controller. You may want to do it in the ApplicationController to make it
        # available to all controllers. For example:
        #
        #   def bigbluebutton_user
        #     User.where(:bigbluebutton_admin => true).first
        #   end
        #
        # Note that BigbluebuttonRails assumes that the returned object has
        # a method called 'name' that returns the user's full name.
        def bigbluebutton_user
          current_user
        end

        # Returns the role that the current user has in the room 'room'.
        # Possibilities:
        #   :moderator
        #   :attendee
        # You may want to redefine this method in your controllers to define
        # real roles to the users. By default, everyone has moderator permissions.
        # Redefine it in your ApplicationController to make it available to all
        # controllers. For example:
        #
        #   def bigbluebutton_role(@room)
        #     r = Roles.where(:bigbluebutton_room_id => @room.id).
        #               where(:user_id => current_user.id).
        #               first
        #     r.role
        #   end
        #
        def bigbluebutton_role(room)
          if room.private or current_user.nil?
            nil # ask for a password
          else
            :moderator
          end
        end

      end
    end

  end

end
