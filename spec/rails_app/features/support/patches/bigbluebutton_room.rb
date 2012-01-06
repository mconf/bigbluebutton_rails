class BigbluebuttonRoom < ActiveRecord::Base

  protected

  def select_server
    self.server
  end

end
