class BigbluebuttonRecording < ActiveRecord::Base
  belongs_to :room, :class_name => 'BigbluebuttonRoom'

  validates :room_id, :presence => true

  validates :recordingid,
            :presence => true,
            :uniqueness => true

  attr_accessible :recordingid, :meetingid, :name, :published, :start_time,
                  :end_time

  has_many :metadata,
           :class_name => 'BigbluebuttonMetadata',
           :foreign_key => 'recording_id',
           :dependent => :destroy

  has_many :playback_formats,
           :class_name => 'BigbluebuttonPlaybackFormat',
           :foreign_key => 'recording_id',
           :dependent => :destroy

end
