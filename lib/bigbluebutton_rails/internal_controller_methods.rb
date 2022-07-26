module BigbluebuttonRails

  # Module with common methods included in the internal controllers used in the gem.
  module InternalControllerMethods

    def self.included(base)
      base.class_eval do

        # A wrapper around Rails' `redirect_to` to give priority to a possible url
        # in the params. It's useful to have this option so that the application can
        # define to where some methods should redirect after finishing.
        def redirect_to_using_params(options={}, response_status={})
          is_relative = !!(params[:redir_url] =~ /^\/[^\/\\]/)
          if !params[:redir_url].blank? && is_relative
            redirect_to params[:redir_url], response_status
          else
            if options == :back
              redirect_back fallback_location: options, **response_status
            else
              redirect_to options, response_status
            end
          end
        end

        # Will redirect to a url defined in `params`, if any. Otherwise, renders the
        # view `action`.
        def redirect_to_params_or_render(action=nil, response_status={})
          is_relative = params[:redir_url] =~ /^\/[^\/\\]/
          if !params[:redir_url].blank? && is_relative
            redirect_to params[:redir_url], response_status
          else
            render(action, response_status)
          end
        end

        # Redirects to:
        #   1. A redirect URL set in the parameters of the current URL; or
        #   2. To `:back`, if the referer is set; or
        #   3. To `options` if the previous failed.
        def redirect_to_using_params_or_back(options={}, response_status={})
          unless params[:redir_url].blank?
            redirect_to params[:redir_url], response_status
          else
            redirect_back fallback_location: options, **response_status
          end
        end

      end
    end

  end

end
