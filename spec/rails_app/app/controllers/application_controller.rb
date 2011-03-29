class ApplicationController < ActionController::Base
  protect_from_forgery

#  def bigbluebutton_user
#    User.new
#  end

end

class User
  attr_accessor :name

  def initialize
    self.name = "Chuck"
  end
end
