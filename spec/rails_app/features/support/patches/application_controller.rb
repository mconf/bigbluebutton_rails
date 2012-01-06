# "Mock" the application controller so we can set the logged user from our features
class ApplicationController < ActionController::Base

  def self.set_user(user)
    @@user = user
  end

  def bigbluebutton_user
    @@user
  end

end
