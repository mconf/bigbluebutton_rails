class ApplicationController < ActionController::Base
  protect_from_forgery

  # TODO: return a real user (use devise?)
  def bigbluebutton_user
    @user ||= User.new
  end

end

class User
  attr_accessor :name

  def initialize
    self.name = "Chuck"
  end
end
