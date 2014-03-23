module BigbluebuttonRails

  # Module that is automatically included into all controllers.
  module ControllerMethods

    def self.included(base)
      base.class_eval do

        helper_method :bigbluebutton_user, :bigbluebutton_role

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

        # Returns the role that the current user has in the room 'room'. Return values:
        #   :moderator      # the user has attendee permissions
        #   :attendee       # the user has moderator permissions
        #   :password       # the user must enter a password that will define his role
        #   nil             # no role at all (the room is blocked to this user)
        #
        # Returning :moderator or :attendee means that the current user has access
        # to the room and has moderator or attendee privileges, respectively.
        # Returning :password indicates that the user must enter a password to define
        # his role in the room.
        # At last, returning nil means that the user cannot access access this room
        # at all. BigbluebuttonRails::RoomController will thrown an exception of the
        # class BigbluebuttonRails::RoomAccessDenied in this case. By default rails will
        # show an error page whenever an exception is thrown (and not catch). To show
        # a better-looking page, add in your ApplicationController a block to catch the
        # exception, such as:
        #
        #   rescue_from BigbluebuttonRails::RoomAccessDenied do |exception|
        #     flash[:error] = "You don't have permission to access this room!"
        #     redirect_to root_url
        #   end
        #
        # You may want to redefine this method in your application to define
        # real roles to the users. By default, if the room is not private and the user
        # is logged, he will have moderator permissions. Otherwise, he must enter
        # a password. Redefine it in your ApplicationController to make it available
        # to all controllers. For example:
        #
        #   def bigbluebutton_role(@room)
        #
        #     # the owner is the moderator
        #     if @room.owner == bigbluebutton_user
        #       :moderator
        #
        #     # only friends are allowed to enter
        #     elsif @room.owner.friends.include? bigbluebutton_user
        #       if @room.private
        #         :password # with password if the room is private
        #       else
        #         :attendee
        #       end
        #
        #     # not a friend? you're not allowed in
        #     else
        #       nil
        #     end
        #
        #   end
        #
        def bigbluebutton_role(room)
          if room.private or bigbluebutton_user.nil?
            :password # ask for a password
          else
            :moderator
          end
        end

        # Method used called right before a meeting is created to check
        # whether the current user ('bigbluebutton_user') is allowed to create
        # the meeting in the target room.
        # By default any moderator can create meetings.
        # The parameter 'room' is the BigbluebuttonRoom where the meeting is about
        # to be created. And 'role' is the role already defined for the user
        # (:moderator, :attendee, etc).
        #
        # You may want to override this in your ApplicationController to
        # implement your own logic, for example:
        #
        #   def bigbluebutton_can_create?(room, role)
        #     if role == :moderator && bigbluebutton_user.admin?
        #       true
        #     else
        #       false
        #     end
        #   end
        #
        def bigbluebutton_can_create?(room, role)
          role == :moderator
        end

        # Method called right before a meeting is created to get options that should receive
        # priority over the options saved in the database when sending the <tt>create</tt>API
        # call.
        # The parameter 'room' is the BigbluebuttonRoom where the meeting is about
        # to be created.
        #
        # By default, all options send in a 'create' API call are taken from the
        # options saved in the database for the target room. This includes, for example,
        # the meeting's name, dial number, welcome message, if it should be recorded or not.
        # This method can return a hash of options to force some of these options to be
        # different from what is stored in the database. For example, if a room should *not* be
        # recorded in case unprivileged users create it, this method can return <tt>{ record: false }</tt>
        # to force the <tt>record</tt> flag to be false.
        #
        # You may want to override this in your ApplicationController to implement your own
        # own logic, if needed. For example:
        #
        #   def bigbluebutton_create_options(room)
        #     can_record = room.record && bigbluebutton_user.can_record?
        #     { record: can_record }
        #     end
        #   end
        #
        def bigbluebutton_create_options(room)
          {}
        end

      end
    end

  end

end
