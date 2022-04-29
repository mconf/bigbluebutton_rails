class BigbluebuttonRecording < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  # NOTE: when adding new attributes to recordings, add them to `recording_changed?`

  belongs_to :server, class_name: 'BigbluebuttonServer'
  belongs_to :room, class_name: 'BigbluebuttonRoom'
  belongs_to :meeting, class_name: 'BigbluebuttonMeeting'

  before_destroy :delete_from_server!

  validates :server, :presence => true

  validates :recordid,
            :presence => true,
            :uniqueness => true

  has_many :metadata,
           :class_name => 'BigbluebuttonMetadata',
           :as => :owner,
           :dependent => :destroy

  has_many :playback_formats,
           :class_name => 'BigbluebuttonPlaybackFormat',
           :foreign_key => 'recording_id',
           :dependent => :destroy

  scope :published, -> { where(:published => true) }

  serialize :recording_users, Array

  DELETE_STATUS = {
    notFound: 'notFound'
  }

  STATES = {
    processing: 'processing',
    processed: 'processed',
    published: 'published',
    unpublished: 'unpublished'
  }

  def self.delete_status
    DELETE_STATUS
  end

  def to_param
    self.recordid
  end

  def is_published?
    self.state.eql?(BigbluebuttonRecording::STATES[:published]) || self.state.eql?(BigbluebuttonRecording::STATES[:unpublished])
  end

  def get_token(user, ip)
    server = BigbluebuttonServer.default
    user.present? ? authName = user.username : authName = "anonymous"
    api_token = server.api.send_api_request(:getRecordingToken, { authUser: authName, authAddr: ip, meetingID: self.recordid })
    str_token = api_token[:token]
    str_token
  end

  # Passing it on the url
  #
  def token_url(user, ip, playback)
    auth_token = get_token(user, ip)
    if auth_token.present?
      uri = playback.url
      uri += URI.parse(uri).query.blank? ? "?" : "&"
      uri += "token=#{auth_token}"
      uri
    end
  end

  def default_playback_format
    playback_formats.joins(:playback_type)
      .where("bigbluebutton_playback_types.default = ?", true).first
  end

  # Remove this recording from the server
  def delete_from_server!
    if self.server.present?
      begin
        self.server.send_delete_recordings(self.recordid)
      rescue BigBlueButton::BigBlueButtonException => e
        if e.key == DELETE_STATUS[:notFound]
          logger.info "Recording #{id} not found on server."
          return true
        end

        logger.error "Could not delete the recording #{self.id} from the server. API error: #{e}"
        return false
      end
    else
      false
    end
  end

  # Returns the overall (i.e. for all recordings) average length of recordings in seconds
  # Uses the length of the default playback format
  def self.overall_average_length
    avg = BigbluebuttonPlaybackFormat.joins(:playback_type)
          .where("bigbluebutton_playback_types.default = ?", true).average(:length)
    avg.nil? ? 0 : (avg.truncate(2) * 60)
  end

  # Returns the overall (i.e. for all recordings) average size of recordings in bytes
  # Uses the length of the default playback format
  def self.overall_average_size
    avg = BigbluebuttonRecording.average(:size)
    avg.nil? ? 0 : avg
  end

  # Compares a recording from the db with data from a getRecordings call.
  # If anything changed in the recording, returns true.
  # We select only the attributes that are saved and turn it all into sorted arrays
  # to compare. If new attributes are stored in recordings, they should be added here.
  #
  # This was created to speed up the full sync of recordings.
  # In the worst case the comparison is wrong and we're updating them all (same as
  # not using this method at all, which is ok).
  def self.recording_changed?(recording, data)
    begin
      # the attributes that are considered in the comparison
      keys = [ # rawSize is not stored at the moment
        :end_time, :meetingid,  :metadata, :playback, :published,
        :recordid, :size, :start_time, :state, :name
      ]
      keys_formats = [ # :size, :processingTime are not stored at the moment
        :length, :type, :url
      ]

      # the data from getRecordings
      data_clone = data.deep_dup
      data_clone[:size] = data_clone[:size].to_s if data_clone.key?(:size)
      data_clone[:metadata] = data_clone[:metadata].sort if data_clone.key?(:metadata)
      if data_clone.key?(:playback) && data_clone[:playback].key?(:format)
        data_clone[:playback][:format] = [data_clone[:playback][:format]] unless data_clone[:playback][:format].is_a?(Array)
        data_clone[:playback] = data_clone[:playback][:format].map{ |f|
          f.slice(*keys_formats).sort
        }.sort
      else
        data_clone[:playback] = []
      end
      data_clone[:end_time] = data_clone[:end_time].to_i if data_clone.key?(:end_time)
      data_clone[:start_time] = data_clone[:start_time].to_i if data_clone.key?(:start_time)
      data_clone = data_clone.slice(*keys)
      data_sorted = data_clone.sort

      # the data from the recording in the db
      attrs = recording.attributes.symbolize_keys.slice(*keys)
      attrs[:size] = attrs[:size].to_s if attrs.key?(:size)
      attrs[:metadata] = recording.metadata.pluck(:name, :content).map{ |i| [i[0].to_sym, i[1]] }.sort
      attrs[:playback] = recording.playback_formats.map{ |f|
        r = f.attributes.symbolize_keys.slice(*keys_formats)
        r[:type] = f.format_type
        r.sort
      }.sort
      attrs = attrs.sort

      # compare
      data_sorted.to_s != attrs.to_s
    rescue StandardError => e
      logger.error "Error comparing recordings: #{e.inspect}"
      true # always update recordings if on error
    end
  end

  # Syncs the recordings in the db with the array of recordings in 'recordings',
  # as received from BigBlueButtonApi#get_recordings.
  # Will add new recordings that are not in the db yet and update the ones that
  # already are (matching by 'recordid'). Will NOT delete recordings from the db
  # if they are not in the array but instead mark them as unavailable.
  #
  # server:: The BigbluebuttonServer from which the recordings were fetched.
  # recordings:: The response from getRecordings.
  # sync_scope:: The scope to which these recordings are part of. If we fetched all recordings
  #   in a server, the scope is all recordings in the server; if we fetched only recordings
  #   for a room, the scope is the recordings of this room. This is used to set `available`
  #   in the recordings that might not be in the server anymore.
  # sync_started_at:: Moment when the getRecordings call that returned the `recordings`
  #   was made. Used so we don't set `available` on recordings created during the
  #   synchronization process.
  #
  # TODO: catch exceptions on creating/updating recordings
  def self.sync(server, recordings, sync_scope=nil, sync_started_at=nil)
    logger.info "Sync recordings: starting a sync for server=#{server.url};#{server.secret} sync_scope=\"#{sync_scope&.to_sql}\""

    recordings.each do |rec|
      rec_obj = BigbluebuttonRecording.find_by(recordid: rec[:recordID])
      rec_data = adapt_recording_hash(rec)
      changed = !rec_obj.present? || self.recording_changed?(rec_obj, rec_data)

      if changed
        logger.info "Sync recordings: detected that the recording changed #{rec[:recordID]}"
        BigbluebuttonRecording.transaction do
          if rec_obj
            logger.info "Sync recordings: updating recording #{rec[:recordID]}"
            logger.debug "Sync recordings: updating recording with data #{rec_data.inspect}"
            self.update_recording(server, rec_obj, rec_data)
          else
            logger.info "Sync recordings: creating recording #{rec[:recordID]}"
            logger.debug "Sync recordings: creating recording with data #{rec_data.inspect}"
            self.create_recording(server, rec_data)
          end
        end
      end
    end
    cleanup_playback_types

    # Set as unavailable the recordings that are not in the list returned by getRecordings, but
    # only if there is a scope set, otherwise we don't know how the call to getRecordings was filtered.
    # Uses the scope passed to figure out which recordings should be marked as unavailable.
    if sync_scope.present?
      sync_started_at = DateTime.now if sync_started_at.nil?

      recordIDs = recordings.map{ |rec| rec[:recordID] }
      if recordIDs.length <= 0
        # empty response, all recordings in the scope are unavailable
        sync_scope.
          where(available: true).
          where("created_at <= ?", sync_started_at).
          update_all(available: false)
      else
        # non empty response, mark as unavailable all recordings in the scope that
        # were not returned by getRecording
        sync_scope.
          where(available: true).where.not(recordid: recordIDs).
          where("created_at <= ?", sync_started_at).
          update_all(available: false)
        sync_scope.
          where(available: false, recordid: recordIDs).
          where("created_at <= ?", sync_started_at).
          update_all(available: true)
      end
    end

    logger.info "Sync recordings: finished a sync for server=#{server.url};#{server.secret} sync_scope=\"#{sync_scope&.to_sql}\""
  end

  protected

  # Adapt keys in 'hash' from bigbluebutton-api-ruby's (the way they are returned by
  # BigBlueButton's API) format to ours (more rails-like).
  def self.adapt_recording_hash(hash)
    new_hash = hash.clone
    mappings = {
      :recordID => :recordid,
      :meetingID => :meetingid,
      :startTime => :start_time,
      :endTime => :end_time
    }
    new_hash.keys.each { |k| new_hash[ mappings[k] ] = new_hash.delete(k) if mappings[k] }
    new_hash
  end

  def self.adapt_recording_users(original)
    if original.present? && original.size > 0
      users = original[:user]
      users = [users] unless users.is_a?(Array)
      users = users.map{ |u|
        id = u[:externalUserID]
        begin
          id = Integer(id)
        rescue
        end
        id
      }
      return users
    end
  end

  # Updates the BigbluebuttonRecording 'recording' with the data in the hash 'data'.
  # The format expected for 'data' follows the format returned by
  # BigBlueButtonApi#get_recordings but with the keys already converted to our format.
  def self.update_recording(server, recording, data)
    recording.server = server
    recording.room = BigbluebuttonRails.configuration.match_room_recording.call(data)
    recording.attributes = data.slice(:meetingid, :name, :published, :start_time, :end_time, :size, :state)
    recording.available = true
    recording.meeting = BigbluebuttonRecording.find_matching_meeting(recording)
    recording.recording_users = adapt_recording_users(data[:recordingUsers])
    recording.save!

    sync_additional_data(recording, data)
  end

  # Creates a new BigbluebuttonRecording with the data from 'data'.
  # The format expected for 'data' follows the format returned by
  # BigBlueButtonApi#get_recordings but with the keys already converted to our format.
  def self.create_recording(server, data)
    filtered = data.slice(:recordid, :meetingid, :name, :published, :start_time, :end_time, :size, :state)
    recording = BigbluebuttonRecording.create(filtered)
    recording.available = true
    recording.room = BigbluebuttonRails.configuration.match_room_recording.call(data)
    recording.server = server
    recording.meeting = BigbluebuttonRecording.find_matching_meeting(recording)
    recording.recording_users = adapt_recording_users(data[:recordingUsers])
    recording.save!

    sync_additional_data(recording, data)
  end

  # Syncs data that's not directly stored in the recording itself but in
  # associated models (e.g. metadata, meeting and playback formats).
  # The format expected for 'data' follows the format returned by
  # BigBlueButtonApi#get_recordings but with the keys already converted to our format.
  def self.sync_additional_data(recording, data)
    sync_metadata(recording, data[:metadata]) if data[:metadata]
    BigbluebuttonMeeting.update_meeting_creator(recording)
    if data[:playback] and data[:playback][:format]
      sync_playback_formats(recording, data[:playback][:format])
    end
  end

  # Syncs the metadata objects of 'recording' with the data in 'metadata'.
  # The format expected for 'metadata' follows the format returned by
  # BigBlueButtonApi#get_recordings but with the keys already converted to our format.
  def self.sync_metadata(recording, metadata)
    # keys are stored as strings in the db
    received_metadata = metadata.clone.stringify_keys

    # get all metadata for this recording
    # note: it's a little slower than removing all metadata and adding again,
    # but it's cleaner to just update it and the loss of performance is small
    query = { owner_id: recording.id, owner_type: recording.class.to_s }
    metas = BigbluebuttonMetadata.where(query).all

    # batch insert all metadata
    columns = [ :id, :name, :content, :owner_id, :owner_type ]
    values = []
    received_metadata.each do |name, content|
      id = metas.select{ |m| m.name == name }.first.try(:id)
      values << [ id, name, content, recording.id, recording.class.to_s ]
    end
    BigbluebuttonMetadata.import! columns, values, validate: true,
                                  on_duplicate_key_update: [:name, :content]

    # delete all that doesn't exist anymore
    BigbluebuttonMetadata.where(query).where.not(name: received_metadata.keys).delete_all
  end

  # Syncs the playback formats objects of 'recording' with the data in 'formats'.
  # The format expected for 'formats' follows the format returned by
  # BigBlueButtonApi#get_recordings but with the keys already converted to our format.
  def self.sync_playback_formats(recording, formats)

    # clone and make it an array if it's a hash with a single format
    formats_copy = formats.clone
    formats_copy = [formats_copy] if formats_copy.is_a?(Hash)

    # remove all formats for this recording
    # note: easier than updating the formats because they don't have a clear key
    # to match by
    BigbluebuttonPlaybackFormat.where(recording_id: recording.id).delete_all

    # batch insert all playback formats
    columns = [ :recording_id, :url, :length , :playback_type_id ]
    values = []
    formats_copy.each do |format|
      unless format[:type].blank?
        playback_type = BigbluebuttonPlaybackType.find_by(identifier: format[:type])
        if playback_type.nil?
          downloadable = BigbluebuttonRails.configuration.downloadable_playback_types.include?(format[:type])
          attrs = {
            identifier: format[:type],
            visible: true,
            downloadable: downloadable
          }
          playback_type = BigbluebuttonPlaybackType.create!(attrs)
        end

        values << [ recording.id, format[:url], format[:length].to_i, playback_type.id ]
      end
    end
    BigbluebuttonPlaybackFormat.import! columns, values, validate: true
  end

  # Remove the unused playback types from the list.
  def self.cleanup_playback_types
    ids = BigbluebuttonPlaybackFormat.uniq.pluck(:playback_type_id)
    BigbluebuttonPlaybackType.destroy_all(['id NOT IN (?)', ids])
  end

  # Finds the BigbluebuttonMeeting that generated this recording. The meeting is searched using
  # the recording's recordid to match with a meeting's internal_meeting_id. If it's not found
  # this way, we try with the meetingid associated with this recording and the create time of
  # the meeting. There are some flexible clauses that try to match very close or truncated
  # timestamps from recordings start times to meeting create times.
  def self.find_matching_meeting(recording)
    meeting = nil
    unless recording.nil? #or recording.room.nil?
      record_id = recording.recordid
      meeting = BigbluebuttonMeeting.where(internal_meeting_id: record_id).last
      if meeting.nil? && !recording.start_time.nil?
        start_time = recording.start_time
        meeting = BigbluebuttonMeeting.where("meetingid = ? AND create_time = ?", recording.meetingid, start_time).last
          if meeting.nil?
            meeting = BigbluebuttonMeeting.where("meetingid = ? AND create_time DIV 1000 = ?", recording.meetingid, start_time).last
          end
          if meeting.nil?
            div_start_time = (start_time/10)
            meeting = BigbluebuttonMeeting.where("meetingid = ? AND create_time DIV 10 = ?", recording.meetingid, div_start_time).last
          end
          if meeting.nil?
            meeting = BigbluebuttonMeeting.create_meeting_record_from_recording(recording)
            logger.info "Recording: meeting created for the recording #{recording.inspect}: #{meeting.inspect}"
          else
            logger.info "Recording: meeting found for the recording #{recording.inspect}: #{meeting.inspect}"
          end
      end
    end

    meeting
  end
end
