class Bigbluebutton::WebhooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json
  before_action :verify_webhooks_enabled
  before_action :validate_caller

  def index
    extra_args = {}
    extra_args[:server_id] = @server.id unless @server.nil?
    head BigbluebuttonRails::Webhooks.parse(params['event'], extra_args)
  end

  private

  def verify_webhooks_enabled
    unless BigbluebuttonRails.configuration.use_webhooks
      # head :not_implemented # 501
      head :no_content # 204
    end
  end

  def validate_caller
    # check if there is a secret in the headers
    secret = request.headers['HTTP_AUTHORIZATION']
    return head :forbidden if secret.blank? # 403

    # check if there's a server in the db with this secret
    secret = secret.gsub('Bearer ', '')
    @server = BigbluebuttonServer.find_by(secret: secret)
    return head :forbidden if @server.nil? # 403

    # check if the domain matches the server with the matched secret
    domain = params['domain']
    head :forbidden if domain != URI.parse(@server.url).host # 403
  end
end
