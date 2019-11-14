class BigbluebuttonRailsTo230 < ActiveRecord::Migration
  def self.up
    rename_column :bigbluebutton_rooms, :param, :slug
    rename_column :bigbluebutton_servers, :param, :slug
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
    rename_column :bigbluebutton_servers, :slug, :param
    rename_column :bigbluebutton_rooms, :slug, :param
    add_column :bigbluebutton_meetings, :got_stats, :string
  end
end
