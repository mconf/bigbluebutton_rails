class Bigbluebutton::ServersController < ApplicationController

  respond_to :html
  respond_to :json, :only => [:index, :show, :new, :create, :update, :destroy]

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
          message = t('bigbluebutton_rails.servers.notice.create.success')
          redirect_to(@server, :notice => message)
        }
        format.json { render :json => @server, :status => :created }
      else
        format.html { render :action => "new" }
        format.json { render :json => @server.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @server = BigbluebuttonServer.find(params[:id])

    respond_with @server do |format|
      if @server.update_attributes(params[:bigbluebutton_server])
        format.html {
          message = t('bigbluebutton_rails.servers.notice.update.success')
          redirect_to(@server, :notice => message)
        }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @server.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @server = BigbluebuttonServer.find(params[:id])
    @server.destroy

    respond_with do |format|
      format.html { redirect_to(bigbluebutton_servers_url) }
      format.json { head :ok }
    end
  end
end
