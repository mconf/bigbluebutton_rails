require 'spec_helper'

describe BigbluebuttonRails::InternalControllerMethods, type: :controller do
  describe "#redirect_to_using_params" do
    let(:options) { { custom_options: 'option' } }
    let(:response_status) { 123 }

    controller do
      include BigbluebuttonRails::InternalControllerMethods
      def index
        options = { custom_options: 'option' }
        response_status = 123
        @result = redirect_to_using_params(options, response_status).freeze
        render :nothing => true
      end
    end

    it "redirects to the options passed if params[:redir_url] not set" do
      controller.should_receive(:redirect_to).with(options, response_status)
      get :index
    end

    it "redirects to params[:redir_url] if set" do
      redir_url = '/testing/redir'
      controller.should_receive(:redirect_to).with(redir_url, response_status)
      get :index, redir_url: redir_url
    end

    it "doesn't redirect to params[:redir_url] if it's an external URL" do
      redir_url = 'https://google.com'
      controller.should_receive(:redirect_to).with(options, response_status)
      get :index, redir_url: redir_url
    end
  end

  describe "#redirect_to_params_or_render" do
    let(:action) { :test }
    let(:response_status) { 123 }

    controller do
      include BigbluebuttonRails::InternalControllerMethods
      def index
        action = :test
        response_status = 123
        redirect_to_params_or_render(action, response_status)
        render :nothing => true
      end
    end

    it "renders the action if params[:redir_url] not set" do
      controller.should_not_receive(:redirect_to)
      controller.should_receive(:render).with(action, response_status)
      controller.should_receive(:render).with({ nothing: true })
      # there's an empty call to 'render' at the end for some reason
      controller.should_receive(:render).with(no_args)
      get :index
    end

    it "redirects to params[:redir_url] if set" do
      redir_url = '/testing/redir'
      controller.should_receive(:redirect_to).with(redir_url, response_status)
      get :index, redir_url: redir_url
    end

    it "doesn't redirect to params[:redir_url] if it's an external URL" do
      redir_url = 'https://google.com'
      controller.should_not_receive(:redirect_to)
      controller.should_receive(:render).with(action, response_status)
      controller.should_receive(:render).with({ nothing: true })
      # there's an empty call to 'render' at the end for some reason
      controller.should_receive(:render).with(no_args)
      get :index, redir_url: redir_url
    end
  end
end
