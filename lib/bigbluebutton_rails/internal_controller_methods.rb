module BigbluebuttonRails

  # Module with common methods included in the internal controllers used in the gem.
  module InternalControllerMethods

    def self.included(base)
      base.class_eval do

        # A wrapper around Rails' `redirect_to` to give priority to a possible url
        # in the params. It's useful to have this option so that the application can
        # define to where some methods should redirect after finishing.
        def redirect_to_using_params(options={}, response_status={})
          unless params[:redir_url].blank?
            redirect_to params[:redir_url], response_status
          else
            redirect_to options, response_status
          end
        end

        # Will redirect to a url defined in `params`, if any. Otherwise, renders the
        # view `action`.
        def redirect_to_params_or_render(action=nil, response_status={})
          unless params[:redir_url].blank?
            redirect_to params[:redir_url], response_status
          else
            render action, response_status
          end
        end

        # Redirects to `:back` if the referer is set, otherwise redirects to `options`.
        def redirect_to_back(options={}, response_status={})
          if !request.env["HTTP_REFERER"].blank? and request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
            redirect_to :back, response_status
          else
            redirect_to options, response_status
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
            redirect_to_back options, response_status
          end
        end

      end
    end

  end

end
