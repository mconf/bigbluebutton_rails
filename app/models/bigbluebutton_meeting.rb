# coding: utf-8
class BigbluebuttonMeeting < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :room, :class_name => 'BigbluebuttonRoom'

  has_one :recording,
          :class_name => 'BigbluebuttonRecording',
          :foreign_key => 'meeting_id',
          :dependent => :destroy

  has_many :attendees,
           :class_name => 'BigbluebuttonAttendee',
           :dependent => :destroy

  validates :room, :presence => true

  validates :meetingid, :presence => true, :length => { :minimum => 1, :maximum => 100 }

  validates :create_time, :presence => true
  validates :create_time, :uniqueness => { :scope => :room_id }

  validates :title, :length => { :maximum => 255 }

  # Whether the meeting was created by the `user` or not.
  def created_by?(user)
    unless user.nil?
      userid = user.send(BigbluebuttonRails.configuration.user_attr_id)
      self.creator_id == userid
    else
      false
    end
  end

  # Creates a meeting using information from a room. Called in the rooms model.
  def self.create_meeting_record_from_room(room, response, server, user, user_opts)
    current_meeting = room.get_current_meeting
    return if current_meeting&.create_time == response[:createTime]

    # to make sure there's no other meeting related to this room that
    # has not yet been set as ended
    room.finish_meetings

    attrs = {
      room: room,
      server_url: server.url,
      server_secret: server.secret,
      meetingid: room.meetingid,
      name: room.name,
      title: room.name,
      recorded: room.record_meeting,
      create_time: response[:createTime],
      running: response[:running],
      ended: false,
      internal_meeting_id: response[:internalMeetingID]
    }

    metadata = response[:metadata]
    unless metadata.nil?
      begin
        attrs[:creator_id] = metadata[BigbluebuttonRails.configuration.metadata_user_id].to_i
        attrs[:creator_name] = metadata[BigbluebuttonRails.configuration.metadata_user_name]
      rescue
        attrs[:creator_id] = nil
        attrs[:creator_name] = nil
      end
    end

    # the parameters the user might have overwritten in the create call
    # need to be mapped to the name of the attrs in BigbluebuttMeeting
    # note: recorded is not in the API response, so we can't just get these
    # attributes from there
    attrs_user = {
      meetingid: user_opts[:meetingID],
      name: user_opts[:name],
      recorded: user_opts[:record],
      creator_id: user_opts[:creator_id],
      creator_name: user_opts[:creator_name]
    }.delete_if { |k, v| v.nil? }
    attrs.merge!(attrs_user)

    BigbluebuttonMeeting.create(attrs)
  end

  # Creates a meeting using information from a recording. Called inside the recording's model.
  # Creator information is added afterwards in update_meeting_creator(), since the metadata is
  # not on the recording yet.
  def self.create_meeting_record_from_recording(recording)
    attrs = {
      room_id: recording.room_id,
      meetingid: recording.meetingid,
      name: recording.name,
      running: false,
      recorded: true,
      creator_id: nil,
      creator_name: nil,
      server_url: recording.server.url,
      server_secret: recording.server.secret,
      create_time: recording.start_time * 1000,
      ended: true,
      finish_time: recording.end_time,
      title: recording.name,
      internal_meeting_id: recording.recordid
    }

    meeting = BigbluebuttonMeeting.create(attrs) unless recording.room_id.nil?

    meeting
  end

  # Updates the creator_id and creator_name on the recording's meeting.
  # This is done here because the needed metadata is synced to the recording after the meeting creation.
  def self.update_meeting_creator(recording)
    if recording.metadata.present?
      if recording.meeting.present?
        attrs = {}
        begin
          attrs[:creator_id] = recording.metadata.find_by(name: 'bbbrails-user-id').content.to_i
          attrs[:creator_name] = recording.metadata.find_by(name: 'bbbrails-user-name').content
        rescue
          attrs[:creator_id] = nil
          attrs[:creator_name] = nil
        end
        recording.meeting.update_attributes(attrs)
      end
    end
  end
end
