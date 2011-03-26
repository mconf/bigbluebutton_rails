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
        # controller. For example:
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
      end
    end

  end

end
