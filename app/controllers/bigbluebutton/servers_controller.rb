class Bigbluebutton::ServersController < ApplicationController
  include BigbluebuttonRails::InternalControllerMethods

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
    @server = BigbluebuttonServer.new(server_params)

    respond_with @server do |format|
      if @server.save
        format.html {
          message = t('bigbluebutton_rails.servers.notice.create.success')
          redirect_to_using_params @server, :notice => message
        }
        format.json { render :json => @server, :status => :created }
      else
        format.html { redirect_to_params_or_render :new }
        format.json { render :json => @server.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_with @server do |format|
      if @server.update_attributes(server_params)
        format.html {
          message = t('bigbluebutton_rails.servers.notice.update.success')
          redirect_to_using_params @server, :notice => message
        }
        format.json { render :json => true, :status => :ok }
      else
        format.html { redirect_to_params_or_render :edit }
        format.json { render :json => @server.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    # TODO: what if it fails?
    @server.destroy

    respond_with do |format|
      format.html { redirect_to_using_params bigbluebutton_servers_url }
      format.json { render :json => true, :status => :ok }
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

  # Accepts the following parameters in URL:
  # meetings:: A list of meetingIDs to be used as filter.
  # meta_*:: To filter by metadata, where "*" can be anything.
  #
  # For example: fetch_recordings?meetings=meeting1,meeting2&meta_name=value
  def fetch_recordings
    error = false
    begin

      # accept meetingID and meta_* filters
      filter = {}
      filter.merge!({ :meetingID => params[:meetings] }) if params[:meetings]
      params.each do |key, value|
        filter.merge!({ key.to_sym => value }) if key.match(/^meta_/)
      end

      @server.fetch_recordings(filter)
      message = t('bigbluebutton_rails.servers.notice.fetch_recordings.success')
    rescue BigBlueButton::BigBlueButtonException => e
      error = true
      message = e.to_s[0..200]
    end

    respond_with do |format|
      format.html {
        flash[error ? :error : :notice] = message
        redirect_to bigbluebutton_server_path(@server)
      }
      format.json {
        if error
          render :json => { :message => message }, :status => :error
        else
          render :json => true, :status => :ok
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
          redirect_to_using_params recordings_bigbluebutton_server_path(@server), :notice => message
        }
        format.json { render :json => message }
      end
    rescue BigBlueButton::BigBlueButtonException => e
      respond_with do |format|
        format.html {
          flash[:error] = e.to_s[0..200]
          redirect_to_using_params recordings_bigbluebutton_server_path(@server)
        }
        format.json { render :json => e.to_s, :status => :error }
      end
    end
  end

  def server_params
    unless params[:bigbluebutton_server].nil?
      params[:bigbluebutton_server].permit(*server_allowed_params)
    else
      []
    end
  end

  def server_allowed_params
    [ :name, :url, :version, :salt, :param ]
  end

end
