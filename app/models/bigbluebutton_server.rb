class BigbluebuttonServer < ActiveRecord::Base
  has_many :rooms, :class_name => 'BigbluebuttonRoom', :foreign_key => 'server_id'

  validates :name, :presence => true, :length => { :minimum => 1, :maximum => 500 }

  validates :url, :presence => true, :uniqueness => true, :length => { :maximum => 500 }
  validates :url, :format => { :with => /http:\/\/.*\/bigbluebutton\/api/, :message => 'URL should have the pattern http://<server>/bigbluebutton/api' }

  validates :salt, :presence => true, :length => { :minimum => 1, :maximum => 500 }
end
