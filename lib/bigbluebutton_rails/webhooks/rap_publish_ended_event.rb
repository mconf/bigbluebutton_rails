module BigbluebuttonRails
  module Webhooks
    class RapPublishEndedEvent

      # Example:
      # {"data"=>{"type"=>"event", "id"=>"rap-publish-ended", "attributes"=>{"meeting"=>{"internal-meeting-id"=>"5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080", "external-meeting-id"=>"random-960439"}, "record-id"=>"5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080", "success"=>true, "step-time"=>725, "workflow"=>"presentation", "recording"=>{"name"=>"random-960439", "is-breakout"=>"false", "start-time"=>1611333529080, "end-time"=>1611333557383, "size"=>445662, "raw-size"=>788612, "metadata"=>{"isBreakout"=>"false", "meetingId"=>"random-960439", "meetingName"=>"random-960439", "record"=>"true"}, "playback"=>{"format"=>"presentation", "link"=>"https://live-do001.elos.dev/playback/presentation/2.3/5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080", "processing_time"=>6600, "duration"=>14375, "extensions"=>{"preview"=>{"images"=>{"image"=>[{"attributes"=>{"width"=>176, "height"=>136, "alt"=>""}, "value"=>"https://live-do001.elos.dev/presentation/5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1611333529114/thumbnails/thumb-1.png"}, {"attributes"=>{"width"=>176, "height"=>136, "alt"=>""}, "value"=>"https://live-do001.elos.dev/presentation/5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1611333529114/thumbnails/thumb-2.png"}, {"attributes"=>{"width"=>176, "height"=>136, "alt"=>""}, "value"=>"https://live-do001.elos.dev/presentation/5cec32f27a06722121c473e2ebae2c1867d0f3b8-1611333529080/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1611333529114/thumbnails/thumb-3.png"}]}}}, "size"=>445662}, "download"=>{}}}, "event"=>{"ts"=>1611333676}}}
      def self.parse(event)
        # puts "Received the event rap-publish-ended: #{event.inspect}"

        # TODO: capture parse errors
        data = event['data']
        attributes = data['attributes']
        attributes_adapted = RapPublishEndedEvent.adapt_to_api(attributes)

        # BigbluebuttonRecording.sync(self, attributes_adapted, false)
      end

      # Adapts the attributes received in the event to the format they would come in the API
      # so we can use the same methods in BigbluebuttonRecording to sync them
      # TODO: get the attributes and adapt to the format expected by the methods used to sync
      #   data from the api
      def self.adapt_to_api(attributes)
        api_attributes = {
          recordid: attributes['record-id'],
          meetingid: attributes['meeting']['external-meeting-id'],
          start_time: attributes['recording']['start-time'],
          end_time: attributes['recording']['end-time'],
          name: attributes['recording']['name'],
          size: attributes['recording']['size'],
          published: true,
          metadata: attributes['recording']['metadata']&.symbolize_keys,
          playback: attributes['playback']&.symbolize_keys,
          download: attributes['download']&.symbolize_keys
        }
      end

    end
  end
end
