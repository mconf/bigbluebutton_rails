class BigbluebuttonRecording < ActiveRecord::Base
  belongs_to :room, :class_name => 'BigbluebuttonRoom'

  validates :recordid,
            :presence => true,
            :uniqueness => true

  attr_accessible :recordid, :meetingid, :name, :published, :start_time,
                  :end_time

  has_many :metadata,
           :class_name => 'BigbluebuttonMetadata',
           :foreign_key => 'recording_id',
           :dependent => :destroy

  has_many :playback_formats,
           :class_name => 'BigbluebuttonPlaybackFormat',
           :foreign_key => 'recording_id',
           :dependent => :destroy

  def to_param
    self.recordid
  end

  # Syncs the recordings in the db with the array of recordings in 'recordings',
  # as received from BigBlueButtonApi#get_recordings.
  # Will add new recordings that are not in the db yet and update the ones that
  # already are (matching by 'recordid'). Will NOT delete recordings from the db,
  # even if they are not in the array.
  def self.sync(recordings)
    recordings.each do |rec|
      rec_db = BigbluebuttonRecording.find_by_recordid(rec[:recordID])
      if rec_db
        self.update_recording(rec_db, rec)
      else
        self.create_recording(rec)
      end
    end
  end

  protected

  # Updates the BigbluebuttonRecording 'object' with the data in the hash 'data'.
  # The format expected for 'data' follows the format returned by
  # BigBlueButtonApi#get_recordings
  def self.update_recording(object, data)
    data = adapt_recording_hash(data)
    data.slice!(:meetingid, :name, :published, :start_time, :end_time)

    object.update_attributes(data)
  end

  # Creates a new BigbluebuttonRecording 'object' with the data from 'data'.
  # The format expected for 'data' follows the format returned by
  # BigBlueButtonApi#get_recordings
  def self.create_recording(data)
    data = adapt_recording_hash(data)
    data.slice!(:recordid, :meetingid, :name, :published, :start_time, :end_time)

    rec = BigbluebuttonRecording.create data
    rec.save
  end

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

end
