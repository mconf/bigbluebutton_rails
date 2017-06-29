class BigbluebuttonMeeting < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :room, :class_name => 'BigbluebuttonRoom'

  has_one :recording,
          :class_name => 'BigbluebuttonRecording',
          :foreign_key => 'meeting_id',
          :dependent => :nullify

  has_many :attendees,
           :class_name => 'BigbluebuttonAttendee',
           :dependent => :destroy

  validates :room, :presence => true

  validates :meetingid, :presence => true, :length => { :minimum => 1, :maximum => 100 }

  validates :create_time, :presence => true
  validates :create_time, :uniqueness => { :scope => :room_id }

  validates :got_stats, :inclusion => { :in => [nil, 'yes', 'not_supported'] }

  # Whether the meeting was created by the `user` or not.
  def created_by?(user)
    unless user.nil?
      userid = user.send(BigbluebuttonRails.configuration.user_attr_id)
      self.creator_id == userid
    else
      false
    end
  end

  # Calls `getStats` in the server that was used to create the meeting and updates the
  # database with the data in the response.
  # Returns true if found a meeting in `getStats` and was able to parse it all and false
  # in any error or if a meeting is not found.
  def fetch_and_update_stats
    if self.server_url.present? && self.server_secret.present?
      server = BigbluebuttonServer.new(url: self.server_url, secret: self.server_secret)
    else
      server = BigbluebuttonRails.configuration.select_server.call(self.room, :get_stats)
    end

    if server.nil?
      Rails.logger.info "No server found to getStats for the meeting #{self.inspect}"
      return false
    end

    begin
      response = server.api.send_api_request(:getStats, { meetingID: self.meetingid })
    rescue BigBlueButton::BigBlueButtonException => e
      Rails.logger.warn "Error calling getStats, assuming the API call is not supported: #{e.inspect}"
      self.update_attributes(got_stats: "not_supported")
      return false
    end

    if response[:messageKey] == 'noStats'
      Rails.logger.info "No stats found for the meeting #{self.inspect}"
      return false
    end

    begin
      self.parse_get_stats(response)
    rescue StandardError => e
      Rails.logger.error "Error parsing the response of getStats: #{e.inspect}"
      false
    end
  end

  def parse_get_stats(response)
    all_meetings = response[:stats][:meeting]
    all_meetings = [all_meetings] unless all_meetings.is_a?(Array)
    my_meeting = all_meetings.select{ |meetings| meetings[:epochStartTime].to_s == self.create_time.to_s }.first

    if my_meeting.nil?
      Rails.logger.info "No target meeting found in getStats for the meeting #{self.inspect}"
      false
    else
      all_participants = my_meeting[:participants][:participant]
      all_participants = [all_participants] unless all_participants.is_a?(Array)

      all_participants.each do |participant|
        join_epoch = (my_meeting[:epochStartTime].to_i - my_meeting[:startTime].to_i + participant[:joinTime].to_i).to_s
        left_epoch = (my_meeting[:epochStartTime].to_i - my_meeting[:startTime].to_i + participant[:leftTime].to_i).to_s

        BigbluebuttonAttendee.create do |a|
          a.user_id = participant[:userID]
          a.external_user_id = participant[:externUserID]
          a.user_name = participant[:userName]
          a.join_time = join_epoch
          a.left_time = left_epoch
          a.bigbluebutton_meeting_id = self.id
        end
      end
      finish_time = (my_meeting[:epochStartTime].to_i - my_meeting[:startTime].to_i + my_meeting[:endTime].to_i).to_s
      self.update_attributes(got_stats: "yes", finish_time: finish_time)
      true
    end
  end
end
