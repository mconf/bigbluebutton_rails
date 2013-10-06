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
            render action
          end
        end

      end
    end

  end

end
