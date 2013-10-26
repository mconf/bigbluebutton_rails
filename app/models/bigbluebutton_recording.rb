class BigbluebuttonRecording < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :server, :class_name => 'BigbluebuttonServer'
  belongs_to :room, :class_name => 'BigbluebuttonRoom'
  belongs_to :meeting, :class_name => 'BigbluebuttonMeeting'

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

  scope :published, where(:published => true)

  def to_param
    self.recordid
  end

  # Syncs the recordings in the db with the array of recordings in 'recordings',
  # as received from BigBlueButtonApi#get_recordings.
  # Will add new recordings that are not in the db yet and update the ones that
  # already are (matching by 'recordid'). Will NOT delete recordings from the db
  # if they are not in the array but instead mark them as unavailable.
  # 'server' is the BigbluebuttonServer object from which the recordings
  # were fetched.
  #
  # TODO: catch exceptions on creating/updating recordings
  def self.sync(server, recordings)
    recordings.each do |rec|
      rec_obj = BigbluebuttonRecording.find_by_recordid(rec[:recordID])
      rec_data = adapt_recording_hash(rec)
      BigbluebuttonRecording.transaction do
        if rec_obj
          logger.info "Sync recordings: updating recording #{rec_obj.inspect}"
          logger.debug "Sync recordings: recording data #{rec_data.inspect}"
          self.update_recording(server, rec_obj, rec_data)
        else
          logger.info "Sync recordings: creating recording"
          logger.debug "Sync recordings: recording data #{rec_data.inspect}"
          self.create_recording(server, rec_data)
        end
      end
    end

    # set as unavailable the recordings that are not in 'recordings'
    recordIDs = recordings.map{ |rec| rec[:recordID] }
    if recordIDs.length <= 0 # empty response
      BigbluebuttonRecording
        .where(:available => true)
        .update_all(:available => false)
    else
      BigbluebuttonRecording
        .where(:available => true)
        .where("recordid NOT IN (?)", recordIDs)
        .update_all(:available => false)
    end
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

  # Updates the BigbluebuttonRecording 'recording' with the data in the hash 'data'.
  # The format expected for 'data' follows the format returned by
  # BigBlueButtonApi#get_recordings but with the keys already converted to our format.
  def self.update_recording(server, recording, data)
    recording.server = server
    recording.room = BigbluebuttonRails.match_room_recording(data)
    recording.attributes = data.slice(:meetingid, :name, :published, :start_time, :end_time)
    recording.available = true
    recording.save!

    sync_additional_data(recording, data)
  end

  # Creates a new BigbluebuttonRecording with the data from 'data'.
  # The format expected for 'data' follows the format returned by
  # BigBlueButtonApi#get_recordings but with the keys already converted to our format.
  def self.create_recording(server, data)
    filtered = data.slice(:recordid, :meetingid, :name, :published, :start_time, :end_time)
    recording = BigbluebuttonRecording.create(filtered)
    recording.available = true
    recording.room = BigbluebuttonRails.match_room_recording(data)
    recording.server = server
    recording.description = I18n.t('bigbluebutton_rails.recordings.default.description', :time => recording.start_time.utc.to_formatted_s(:long))
    recording.meeting = BigbluebuttonRecording.find_matching_meeting(recording)
    recording.save!

    sync_additional_data(recording, data)
  end

  # Syncs data that's not directly stored in the recording itself but in
  # associated models (e.g. metadata and playback formats).
  # The format expected for 'data' follows the format returned by
  # BigBlueButtonApi#get_recordings but with the keys already converted to our format.
  def self.sync_additional_data(recording, data)
    sync_metadata(recording, data[:metadata]) if data[:metadata]
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

    query = { :owner_id => recording.id, :owner_type => recording.class.to_s }
    BigbluebuttonMetadata.where(query).each do |meta_db|

      # the metadata in the db is also in the received data, update it in the db
      if received_metadata.has_key?(meta_db.name)
        meta_db.update_attributes({ :content => received_metadata[meta_db.name] })
        received_metadata.delete(meta_db.name)

      # the metadata is not in the received data, remove from the db
      else
        meta_db.destroy
      end
    end

    # for metadata that are not in the db yet
    received_metadata.each do |name, content|
      attrs = {
        :name => name,
        :content => content,
      }
      meta = BigbluebuttonMetadata.create(attrs)
      meta.owner = recording
      meta.save!
    end
  end

  # Syncs the playback formats objects of 'recording' with the data in 'formats'.
  # The format expected for 'formats' follows the format returned by
  # BigBlueButtonApi#get_recordings but with the keys already converted to our format.
  def self.sync_playback_formats(recording, formats)
    formats_copy = formats.clone

    # make it an array if it's a hash with a single format
    formats_copy = [ formats_copy ] if formats_copy.is_a?(Hash)

    BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).each do |format_db|
      format = formats_copy.select{ |d|
        !d[:type].blank? and d[:type] == format_db.format_type
      }.first

      # the format exists in the hash, update it in the db
      if format
        format_db.update_attributes({ :url => format[:url], :length => format[:length] })
        formats_copy.delete(format)

      # the format is not in the hash, remove from the db
      else
        format_db.destroy
      end
    end

    # for formats that are not in the db yet
    formats_copy.each do |format|
      unless format[:type].blank?
        attrs = { :recording_id => recording.id, :format_type => format[:type],
          :url => format[:url], :length => format[:length].to_i }
        BigbluebuttonPlaybackFormat.create!(attrs)
      end
    end
  end

  # Finds the BigbluebuttonMeeting that generated this recording. The meeting is searched using
  # the room associated with this recording and the create time of the meeting, taken from
  # the recording's ID.
  def self.find_matching_meeting(recording)
    meeting = nil

    unless recording.nil? or recording.room.nil?

      # recordid is something like: 'dd2816950ce2f1e0a928c1a5b8d5b526e9b3e32c-1381978014526'
      # the create time of the meeting is the timestamp at the end
      start_time = recording.recordid.match(/-(\d*)$/)
      unless start_time.nil?
        start_time = start_time[1]
        start_time = Time.at(start_time.to_i).to_datetime.utc
        meeting = BigbluebuttonMeeting.where(:room_id => recording.room.id, :start_time => start_time).last
        logger.info "Recording: meeting found for the recording #{recording.inspect}: #{meeting.inspect}"
      end
    end

    meeting
  end

end
