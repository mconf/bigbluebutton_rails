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

  # Array of <tt>BigbluebuttonMeeting</tt>
  attr_reader :meetings

  after_initialize :init

  # Returns the API object (<tt>BigBlueButton::BigBlueButtonAPI</tt> defined in
  # <tt>bigbluebutton-api-ruby</tt>) associated with this server.
  def api
    if @api.nil?
      @api = BigBlueButton::BigBlueButtonApi.new(self.url, self.salt,
                                                 self.version.to_s, false)
    end
    @api
  end

  # Fetches the meetings currently created in the server (running or not).
  #
  # Using the response, updates <tt>meetings</tt> with a list of <tt>BigbluebuttonMeeting</tt>
  # objects.
  #
  # Triggers API call: <tt>get_meetings</tt>.
  def fetch_meetings
    response = self.api.get_meetings

    # updates the information in the rooms that are currently in BBB
    @meetings = []
    response[:meetings].each do |attr|
      room = BigbluebuttonRoom.find_by_server_id_and_meetingid(self.id, attr[:meetingID])
      if room.nil?
        room = BigbluebuttonRoom.new(:server => self, :meetingid => attr[:meetingID],
                                     :attendee_password => attr[:attendeePW],
                                     :moderator_password => attr[:moderatorPW])
        room.running = attr[:running]
      else
        room.update_attributes(:attendee_password => attr[:attendeePW],
                               :moderator_password => attr[:moderatorPW])
        room.running = attr[:running]
      end

      @meetings << room
    end
  end

  protected

  def init
    # fetched attributes
    @meetings = []
  end

end
