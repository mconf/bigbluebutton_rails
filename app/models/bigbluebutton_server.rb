require 'bigbluebutton_api'

class BigbluebuttonServer < ActiveRecord::Base
  has_many :rooms,
           :class_name => 'BigbluebuttonRoom',
           :foreign_key => 'server_id',
           :dependent => :destroy

  validates :name,
            :presence => true,
            :uniqueness => true,
            :length => { :minimum => 1, :maximum => 500 }

  validates :url,
            :presence => true,
            :uniqueness => true,
            :length => { :maximum => 500 },
            :format => { :with => /http:\/\/.*\/bigbluebutton\/api/,
                         :message => I18n.t('bigbluebutton_rails.servers.errors.url_format') }

  validates :param,
            :presence => true,
            :uniqueness => true,
            :length => { :minimum => 3 },
            :format => { :with => /^[a-zA-Z\d_]+[a-zA-Z\d_-]*[a-zA-Z\d_]+$/,
                         :message => I18n.t('bigbluebutton_rails.servers.errors.param_format') }

  validates :salt,
            :presence => true,
            :length => { :minimum => 1, :maximum => 500 }

  validates :version,
            :presence => true,
            :inclusion => { :in => ['0.64', '0.7'] }

  attr_accessible :name, :url, :version, :salt, :param

  # Array of <tt>BigbluebuttonMeeting</tt>
  attr_reader :meetings

  after_initialize :init
  before_validation :set_param

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
                                     :name => attr[:meetingID], :attendee_password => attr[:attendeePW],
                                     :moderator_password => attr[:moderatorPW], :external => true,
                                     :randomize_meetingid => false, :private => true)
      else
        room.update_attributes(:attendee_password => attr[:attendeePW],
                               :moderator_password => attr[:moderatorPW])
      end
      room.running = attr[:running]

      @meetings << room
    end
  end

  def to_param
    self.param
  end

  protected

  def init
    # fetched attributes
    @meetings = []
  end

  # if :param wasn't set, sets it as :name downcase and parameterized
  def set_param
    if self.param.blank?
      self.param = self.name.parameterize.downcase unless self.name.nil?
    end
  end

end
