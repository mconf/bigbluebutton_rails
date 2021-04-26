module BigbluebuttonRails
  module Webhooks
    module RapPublishEndedEvent
      # Example:
      # {"data"=>{"type"=>"event", "id"=>"rap-publish-ended", "attributes"=>{"meeting"=>{"internal-meeting-id"=>"5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080", "external-meeting-id"=>"random-960439"}, "record-id"=>"5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080", "success"=>true, "step-time"=>725, "workflow"=>"presentation", "recording"=>{"name"=>"random-960439", "is-breakout"=>"false", "start-time"=>1611333529080, "end-time"=>1611333557383, "size"=>445662, "raw-size"=>788612, "metadata"=>{"isBreakout"=>"false", "meetingId"=>"random-960439", "meetingName"=>"random-960439", "record"=>"true"}, "playback"=>{"format"=>"presentation", "link"=>"https://live-do001.elos.dev/playback/presentation/2.3/5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080", "processing_time"=>6600, "duration"=>14375, "extensions"=>{"preview"=>{"images"=>{"image"=>[{"attributes"=>{"width"=>176, "height"=>136, "alt"=>""}, "value"=>"https://live-do001.elos.dev/presentation/5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1611333529114/thumbnails/thumb-1.png"}, {"attributes"=>{"width"=>176, "height"=>136, "alt"=>""}, "value"=>"https://live-do001.elos.dev/presentation/5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1611333529114/thumbnails/thumb-2.png"}, {"attributes"=>{"width"=>176, "height"=>136, "alt"=>""}, "value"=>"https://live-do001.elos.dev/presentation/5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1611333529114/thumbnails/thumb-3.png"}]}}}, "size"=>445662}, "download"=>{}}}, "event"=>{"ts"=>1611333676}}}
      def self.parse(event)
        server = BigbluebuttonServer.find_by(id: event[:server_id])
        if server.nil?
          Rails.logger.warn 'Not syncing, could not find a server with id ' \
                            "#{event['server_id']}."
          return
        end
        # puts "Received the event rap-publish-ended: #{event.inspect}"

        # TODO: capture parse errors
        data = event['data']
        attributes = data['attributes']
        attributes_adapted = RapPublishEndedEvent.adapt_to_api(attributes)

        BigbluebuttonRecording.sync(server, attributes_adapted, false)
      end

      # Adapts the attributes received in the event to the format they would come in the API
      # so we can use the same methods in BigbluebuttonRecording to sync them
      def self.adapt_to_api(attributes)
        recording = attributes['recording']

        playback = recording['playback']&.symbolize_keys
        playback[:format] = adapt_playback_format_to_api(playback)
        api_attributes = {
          meetingid: attributes['meeting']['external-meeting-id'],
          recordid: attributes['record-id'],
          name: recording['name'],
          start_time: recording['start-time'],
          end_time: recording['end-time'],
          size: recording['size'],
          published: true,
          metadata: recording['metadata']&.symbolize_keys,
          playback: playback,
          download: recording['download']&.symbolize_keys
        }
      end

      # Webhook's format is a string (ex. "presentation"), while api's format
      # is a hash with :type, :url and :link.
      # Here we create this hash by extracting (and deleting) the data
      # (:format, :link and :duration) from the webhook event.
      def self.adapt_playback_format_to_api(playback)
        mappings = {
          type: :format,
          url: :link,
          length: :duration
        }
        new_format = {}
        mappings.each do |api_k, webhook_k|
          value = playback.delete(webhook_k)
          new_format[api_k] = value unless value.nil?
        end
        new_format
      end
    end
  end
end
