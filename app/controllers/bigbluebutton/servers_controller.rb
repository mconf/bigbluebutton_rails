class Bigbluebutton::ServersController < ApplicationController

  respond_to :html

  def index
    respond_with(@servers = BigbluebuttonServer.all)
  end

  def show
    respond_with(@server = BigbluebuttonServer.find(params[:id]))
  end

  def new
    respond_with(@server = BigbluebuttonServer.new)
  end

  def edit
    respond_with(@server = BigbluebuttonServer.find(params[:id]))
  end

  def create
    @server = BigbluebuttonServer.new(params[:bigbluebutton_server])

    respond_with @server do |format|
      if @server.save
        format.html {
          message = t('bigbluebutton_rails.servers.notice.successfully_created')
          redirect_to(@server, :notice => message)
        }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @server = BigbluebuttonServer.find(params[:id])

    respond_with @server do |format|
      if @server.update_attributes(params[:bigbluebutton_server])
        format.html {
          message = t('bigbluebutton_rails.servers.notice.successfully_updated')
          redirect_to(@server, :notice => message)
        }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @server = BigbluebuttonServer.find(params[:id])
    @server.destroy
    redirect_to(bigbluebutton_servers_url)
  end
end
