class Bigbluebutton::ServersController < ApplicationController

  respond_to :html
  respond_to :json, :only => [:index, :show, :new, :create, :update, :destroy, :activity, :rooms]
  before_filter :find_server, :except => [:index, :new, :create]

  def index
    respond_with(@servers = BigbluebuttonServer.all)
  end

  def show
    respond_with(@server)
  end

  def new
    respond_with(@server = BigbluebuttonServer.new)
  end

  def edit
    respond_with(@server)
  end

  def activity
    error = false
    begin
      @server.fetch_meetings
      @server.meetings.each do |meeting|
        meeting.fetch_meeting_info
      end
    rescue BigBlueButton::BigBlueButtonException => e
      error = true
      message = e.to_s[0..200]
    end

    # update_list works only for html
    if params[:update_list] && (params[:format].nil? || params[:format].to_s == "html")
      render :partial => 'activity_list', :locals => { :server => @server }
      return
    end

    respond_with @server.meetings do |format|
      # we return/render the fetched meetings even in case of error
      # but we set the error message in the response
      if error
        flash[:error] = message
        format.html { render :activity }
        format.json {
          array = @server.meetings
          array.insert(0, { :message => message })
          render :json => array, :status => :error
        }
      else
        format.html
        format.json
      end
    end
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
        format.html { render :new }
        format.json { render :json => @server.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_with @server do |format|
      if @server.update_attributes(params[:bigbluebutton_server])
        format.html {
          message = t('bigbluebutton_rails.servers.notice.update.success')
          redirect_to(@server, :notice => message)
        }
        format.json { head :ok }
      else
        format.html { render :edit }
        format.json { render :json => @server.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    # TODO: what if it fails?
    @server.destroy

    respond_with do |format|
      format.html { redirect_to(bigbluebutton_servers_url) }
      format.json { head :ok }
    end
  end

  def recordings
    respond_with(@recordings = @server.recordings)
  end

  def rooms
    respond_with(@rooms = @server.rooms)
  end

  def publish_recordings
    self.publish_unpublish(params[:recordings], true)
  end

  def unpublish_recordings
    self.publish_unpublish(params[:recordings], false)
  end

  def fetch_recordings
    error = false
    begin
      filter = {}
      filter.merge!({ :meetingID => params[:meetings] }) if params[:meetings]
      @server.fetch_recordings(filter)
      message = t('bigbluebutton_rails.servers.notice.fetch_recordings.success')
    rescue BigBlueButton::BigBlueButtonException => e
      error = true
      message = e.to_s[0..200]
    end

    respond_with do |format|
      format.html {
        if error
          flash[:error] = message
        else
          flash[:notice] = message
        end
        redirect_to bigbluebutton_server_path(@server)
      }
      format.json {
        if error
          render :json => { :message => message }, :status => :error
        else
          head :ok
        end
      }
    end
  end

  protected

  def find_server
    @server = BigbluebuttonServer.find_by_param(params[:id])
  end

  def publish_unpublish(ids, publish)
    begin
      @server.send_publish_recordings(ids, publish)
      respond_with do |format|
        format.html {
          if publish
            message = t('bigbluebutton_rails.servers.notice.publish_recordings.success')
          else
            message = t('bigbluebutton_rails.servers.notice.unpublish_recordings.success')
          end
          redirect_to(recordings_bigbluebutton_server_path(@server), :notice => message)
        }
        format.json { render :json => message }
      end
    rescue BigBlueButton::BigBlueButtonException => e
      respond_with do |format|
        format.html {
          flash[:error] = e.to_s[0..200]
          redirect_to recordings_bigbluebutton_server_path(@server)
        }
        format.json { render :json => e.to_s, :status => :error }
      end
    end
  end

end
