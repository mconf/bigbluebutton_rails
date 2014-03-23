class User
  attr_accessor :username
  attr_accessor :name
  attr_accessor :id

  def initialize
    self.id = 0
    self.username = "any"
    self.name = "Any"
  end
end
