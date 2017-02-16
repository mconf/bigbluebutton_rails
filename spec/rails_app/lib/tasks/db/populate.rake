require 'forgery'

namespace :db do

  desc "Populate the DB with random test data."
  task :populate => :environment do

    puts "- Destroying all old data"
    BigbluebuttonServer.destroy_all
    BigbluebuttonRoom.destroy_all
    BigbluebuttonRecording.destroy_all
    BigbluebuttonMetadata.destroy_all
    BigbluebuttonPlaybackFormat.destroy_all

    ids = ["presentation", "presentation_video", "slides"]
    3.times do |i|
      params = {
        :identifier => ids[i],
        :visible => Forgery(:basic).boolean
      }
      puts "- Creating playback type #{params[:identifier]}"
      BigbluebuttonPlaybackType.create!(params)
    end

    # Servers
    2.times do |n1|
      params = {
        :name => "Server #{n1}",
        :url => "http://bigbluebutton#{n1}.test.com/bigbluebutton/api",
        :secret => Forgery(:basic).password(:at_least => 30, :at_most => 40),
        :version => '0.9',
        :param => "server-#{n1}"
      }
      puts "- Creating server #{params[:name]}"
      server = BigbluebuttonServer.create!(params)

      # Rooms
      2.times do |n2|
        params = {
          :meetingid => "meeting-#{n1}-#{n2}-" + SecureRandom.hex(4),
          :server => server,
          :name => "Name-#{n1}-#{n2}",
          :attendee_key => Forgery(:basic).password(:at_least => 10, :at_most => 16),
          :moderator_key => Forgery(:basic).password(:at_least => 10, :at_most => 16),
          :welcome_msg => Forgery(:lorem_ipsum).sentences(2),
          :private => false,
          :param => "meeting-#{n1}-#{n2}",
          :external => false,
          :record_meeting => false,
          :duration => 0
        }
        puts "  - Creating room #{params[:name]}"
        room = BigbluebuttonRoom.create!(params)

        # Room metadata
        3.times do |n_metadata|
          params = {
            :name => "#{Forgery(:name).first_name.downcase}-#{n_metadata}",
            :content => Forgery(:name).full_name
          }
          puts "    - Creating room metadata #{params[:name]}"
          metadata = BigbluebuttonMetadata.create(params)
          metadata.owner = room
          metadata.save!
        end

        2.times do |n2|
          params = {
            :server_id => 0,
            :room_id => room.id,
            :meetingid => room.meetingid,
            :name => "Name-#{n1}-#{n2}",
            :create_time => Time.now - rand(5).hours,
            :running => false,
            :recorded => true,
            :creator_id => rand(12),
            :creator_name => "Name-#{n1}-#{n2}",
            :ended => true
          }
          time = params[:create_time]
          puts "    - Creating meeting #{params[:name]}"
          meeting = BigbluebuttonMeeting.create(params)
        end

        # Recordings
        2.times do |n3|
          params = {
            :recordid => "rec-#{n1}-#{n2}-#{n3}-" + SecureRandom.hex(26),
            :meetingid => room.meetingid,
            :name => "Rec-#{n1}-#{n2}-#{n3}",
            :published => true,
            :available => true,
            :start_time => meeting.create_time,
            :end_time => meeting.create_time + rand(5).hours
          }
          time = params[:start_time]
          params[:description] = I18n.t('bigbluebutton_rails.recordings.default.description', :time => time)
          puts "    - Creating recording #{params[:name]}"
          recording = BigbluebuttonRecording.create(params)
          recording.server = server
          recording.room = room
          recording.save!

          # Basic metadata the gem always adds and should always be there
          basic_metadata =
            [{
               :name => BigbluebuttonRails.configuration.metadata_user_id,
               :content => Forgery(:basic).number(:at_most => 1000)
             }, {
               :name => BigbluebuttonRails.configuration.metadata_user_name,
               :content => Forgery(:name).full_name
             }]
          basic_metadata.each do |meta_params|
            metadata = BigbluebuttonMetadata.create(meta_params)
            metadata.owner = recording
            metadata.save!
            puts "      - Creating recording metadata #{meta_params[:name]}"
          end

          # Recording metadata
          3.times do |n_metadata|
            params = {
              :name => "#{Forgery(:name).first_name.downcase}-#{n_metadata}",
              :content => Forgery(:name).full_name
            }
            puts "      - Creating recording metadata #{params[:name]}"
            metadata = BigbluebuttonMetadata.create(params)
            metadata.owner = recording
            metadata.save!
          end

          # Recording playback formats
          playback_types = [1,2,3]
          3.times do |n_format|
            params = {
              :url => "http://" + Forgery(:internet).domain_name + "/playback",
              :length => Forgery(:basic).number
            }
            puts "      - Creating playback format #{params[:format_type]}"
            format = BigbluebuttonPlaybackFormat.create(params)
            format.recording = recording
            id = playback_types[rand(playback_types.length)]
            playback_types.delete(id)
            format.playback_type = BigbluebuttonPlaybackType.find(id)
            format.save!
          end

        end
      end
    end
  end
end
