class BigbluebuttonServer < ActiveRecord::Base
  has_many :bigbluebutton_rooms

  validates :name, :presence => true, :uniqueness => true
  validates :url, :presence => true
  validates :salt, :presence => true

end
