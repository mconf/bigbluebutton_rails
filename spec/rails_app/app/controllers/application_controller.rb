class ApplicationController < ActionController::Base
  protect_from_forgery

  # TODO: return a real user (use devise?)
  def bigbluebutton_user
    @user ||= User.new
  end

end

class User
  attr_accessor :name
  attr_accessor :id

  def initialize
    self.id = 0
    self.name = "Chuck"
  end
end
