Dir[File.join(__dir__, 'webhooks', '*.rb')].each { |file| require file }

module BigbluebuttonRails
  module Webhooks
    def self.parse(events, extra_args = {})
      begin
        json_events = JSON.parse(events)
      rescue JSON::ParserError => e
        Rails.logger.warn "Could not parse a webhook event. Error: #{e.inspect}"
        return :unprocessable_entity # 422
      end

      # TODO: rescue from malformatted event, return error
      json_events = [json_events] unless json_events.is_a?(Array)
      json_events.sort_by { |e| e['data']['event']['ts'] }.each do |json_event|
        name = json_event['data']['id'].gsub(/-/, '_').camelize
        begin
          klass = "#{self.name}::#{name}Event".constantize
        rescue NameError => e
          Rails.logger.info "Could not find a class to process the webhook event #{name}"
          return :ok # 200
        end
        json_event.merge!(extra_args)
        klass.parse(json_event)
      end

      :ok # 200
    end
  end
end
