module BigbluebuttonRails
  module APIControllerMethods

    def self.included(base)
      base.class_eval do

        def map_sort(param, default, allowed=[])
          return default if param.blank? || param.empty?

          param.split(',').inject('') do |memo, obj|
            if obj[0] == '-'
              attr = obj.gsub(/^-/, '')
              order = 'DESC'
            else
              attr = obj
              order = 'ASC'
            end
            if allowed.blank? || allowed.include?(attr)
              memo = "#{memo}," unless memo.blank?
              memo = "#{memo} #{attr} #{order}"
            else
              memo
            end
          end
        end

        def validate_pagination
          param = params[:page]
          if param
            if param[:size]
              size = Integer(param[:size]) rescue false
              return error_invalid_pagination if size.nil? || size < 1
            end
            if param[:number]
              page = Integer(param[:number]) rescue false
              return error_invalid_pagination if page.nil? || page < 1
            end
          end
        end

        def map_pagination(param, default)
          limit = default
          if param && param[:size]
            limit = Integer(param[:size]) rescue false
          end
          limit = default if !limit || limit < 1

          offset = 0
          page = 1
          if param && param[:number]
            page = Integer(param[:number]) rescue false
            page ||= 1
            offset = (page-1)*limit
            offset = 0 if offset < 0
          end

          ["#{offset},#{limit}", page]
        end

        def map_pagination_links(current)
          original = request.original_url

          uri = URI.parse(original)
          query = Rack::Utils.parse_query(uri.query)
          uri.query = Rack::Utils.build_query(query) # just to encode the params

          links = { self: uri.to_s }

          if current - 1 > 0
            query["page[number]"] = current - 1
            uri.query = Rack::Utils.build_query(query)
            links.merge!({ prev: uri.to_s })
          end

          query["page[number]"] = current + 1
          uri.query = Rack::Utils.build_query(query)
          links.merge!({ next: uri.to_s })

          query["page[number]"] = 1
          uri.query = Rack::Utils.build_query(query)
          links.merge!({ first: uri.to_s })

          links
        end

        def error_room_not_found
          msg = t('bigbluebutton_rails.api.rooms.room_not_found.msg')
          title = t('bigbluebutton_rails.api.rooms.room_not_found.title')
          @errors = [BigbluebuttonRails::APIError.new(msg, 404, title)]
          render 'bigbluebutton/api/error'
        end

        def error_room_not_running
          msg = t('bigbluebutton_rails.api.rooms.room_not_running.msg')
          title = t('bigbluebutton_rails.api.rooms.room_not_running.title')
          @errors = [BigbluebuttonRails::APIError.new(msg, 400, title)]
          render 'bigbluebutton/api/error'
        end

        def error_missing_params
          msg = t('bigbluebutton_rails.api.rooms.missing_params.msg')
          title = t('bigbluebutton_rails.api.rooms.missing_params.title')
          @errors = [BigbluebuttonRails::APIError.new(msg, 400, title)]
          render 'bigbluebutton/api/error'
        end

        def error_invalid_pagination
          msg = t('bigbluebutton_rails.api.rooms.invalid_pagination.msg')
          title = t('bigbluebutton_rails.api.rooms.invalid_pagination.title')
          @errors = [BigbluebuttonRails::APIError.new(msg, 400, title)]
          render 'bigbluebutton/api/error'
        end

      end
    end

  end
end
