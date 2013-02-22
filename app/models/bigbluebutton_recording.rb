class BigbluebuttonRecording < ActiveRecord::Base
  belongs_to :server, :class_name => 'BigbluebuttonServer'
  belongs_to :room, :class_name => 'BigbluebuttonRoom'

  validates :server, :presence => true

  validates :recordid,
            :presence => true,
            :uniqueness => true

  attr_accessible :recordid, :meetingid, :name, :published, :start_time,
                  :end_time

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
  # already are (matching by 'recordid'). Will NOT delete recordings from the db,
  # even if they are not in the array.
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
  end

  protected

  # Adapt keys in 'hash' from bigbluebutton-api-ruby's format to ours
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
    recording.save!

    sync_additional_data(recording, data)
  end

  # Creates a new BigbluebuttonRecording with the data from 'data'.
  # The format expected for 'data' follows the format returned by
  # BigBlueButtonApi#get_recordings but with the keys already converted to our format.
  def self.create_recording(server, data)
    filtered = data.slice(:recordid, :meetingid, :name, :published, :start_time, :end_time)
    recording = BigbluebuttonRecording.create(filtered)
    recording.room = BigbluebuttonRails.match_room_recording(data)
    recording.server = server
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
    local_metadata = metadata.clone

    query = { :owner_id => recording.id, :owner_type => recording.class.to_s }
    BigbluebuttonMetadata.where(query).each do |data|
      # the metadata is in the hash, update it in the db
      if local_metadata.has_key?(data.name)
        data.update_attributes({ :content => local_metadata[data.name] })
        local_metadata.delete(data.name)
      # the format is not in the hash, remove from the db
      else
        data.destroy
      end
    end

    # for metadata that are not in the db yet
    local_metadata.each do |name, content|
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

end
