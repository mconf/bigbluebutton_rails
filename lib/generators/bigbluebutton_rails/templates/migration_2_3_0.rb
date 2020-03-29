class BigbluebuttonRailsTo230 < ActiveRecord::Migration
  def self.up
    add_column :bigbluebutton_recordings, :recording_users, :text
    add_column :bigbluebutton_playback_types, :downloadable, :boolean, default: false
    remove_column :bigbluebutton_meetings, :got_stats

    BigbluebuttonPlaybackType.find_each do |type|
      downloadable = BigbluebuttonRails.configuration.downloadable_playback_types.include?(type.identifier)
      type.update_attributes(downloadable: downloadable)
    end
  end

  def self.down
    remove_column :bigbluebutton_playback_types, :downloadable
    remove_column :bigbluebutton_recordings, :recording_users
    add_column :bigbluebutton_meetings, :got_stats, :string
  end
end
