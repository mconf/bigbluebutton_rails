require 'bigbluebutton-api'

class BigbluebuttonServer < ActiveRecord::Base
  has_many :rooms, :class_name => 'BigbluebuttonRoom', :foreign_key => 'server_id',
                   :dependent => :destroy

  validates :name, :presence => true, :length => { :minimum => 1, :maximum => 500 }

  validates :url, :presence => true, :uniqueness => true, :length => { :maximum => 500 }
  validates :url, :format => { :with => /http:\/\/.*\/bigbluebutton\/api/,
    :message => 'URL should have the pattern http://<server>/bigbluebutton/api' }

  validates :salt, :presence => true, :length => { :minimum => 1, :maximum => 500 }

  validates :version, :presence => true, :inclusion => { :in => ['0.64', '0.7'] }

  def api
    if @api.nil?
      @api = BigBlueButton::BigBlueButtonApi.new(self.url, self.salt,
                                                 self.version.to_s, false)
    end
    @api
  end

  attr_reader :meetings

  def fetch_meetings
    response = self.api.get_meetings

    # updates the information in the rooms that are currently in BBB
    @meetings = []
    response[:meetings].each do |attr|
      room = BigbluebuttonRoom.find_by_server_id_and_meeting_id(self.id, attr[:meetingID])

      meeting = BigbluebuttonMeeting.new
      meeting.from_hash(attr)
      meeting.room = room
      @meetings << meeting
    end
  end

end
