class Bigbluebutton::ServersController < ApplicationController

  def index
    @servers = BigbluebuttonServer.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @servers }
    end
  end

  def show
    @server = BigbluebuttonServer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @server }
    end
  end

  def new
    @server = BigbluebuttonServer.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @server }
    end
  end

  def edit
    @server = BigbluebuttonServer.find(params[:id])
  end

  def create
    @server = BigbluebuttonServer.new(params[:bigbluebutton_server])

    respond_to do |format|
      if @server.save
        format.html {
          message = t('bigbluebutton_rails.servers.notice.successfully_created')
          redirect_to(@server, :notice => message)
        }
        format.xml  { render :xml => @server, :status => :created, :location => @server }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @server = BigbluebuttonServer.find(params[:id])

    respond_to do |format|
      if @server.update_attributes(params[:bigbluebutton_server])
        format.html {
          message = t('bigbluebutton_rails.servers.notice.successfully_updated')
          redirect_to(@server, :notice => message)
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @server = BigbluebuttonServer.find(params[:id])
    @server.destroy

    respond_to do |format|
      format.html { redirect_to(bigbluebutton_servers_url) }
      format.xml  { head :ok }
    end
  end
end
