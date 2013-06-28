require 'bigbluebutton_api'

class Bigbluebutton::RoomsController < ApplicationController

  before_filter :find_room, :except => [:index, :create, :new, :auth, :external, :external_auth]
  before_filter :find_server, :only => [:external, :external_auth]

  # set headers only in actions that might trigger api calls
  before_filter :set_request_headers, :only => [:join_mobile, :end, :running, :join, :destroy, :auth, :external_auth]

  respond_to :html, :except => :running
  respond_to :json, :only => [:running, :show, :new, :index, :create, :update]

  def index
    respond_with(@rooms = BigbluebuttonRoom.all)
  end

  def show
    respond_with(@room)
  end

  def new
    respond_with(@room = BigbluebuttonRoom.new)
  end

  def edit
    respond_with(@room)
  end

  def create
    @room = BigbluebuttonRoom.new(params[:bigbluebutton_room])

    if !params[:bigbluebutton_room].has_key?(:meetingid) or
        params[:bigbluebutton_room][:meetingid].blank?
      @room.meetingid = @room.name
    end

    respond_with @room do |format|
      if @room.save
        message = t('bigbluebutton_rails.rooms.notice.create.success')
        format.html {
          redirect_to params[:redir_url] ||= bigbluebutton_room_path(@room), :notice => message
        }
        format.json { render :json => { :message => message }, :status => :created }
      else
        format.html {
          unless params[:redir_url].blank?
            message = t('bigbluebutton_rails.rooms.notice.create.failure')
            redirect_to params[:redir_url], :error => message
          else
            render :new
          end
        }
        format.json { render :json => @room.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_with @room do |format|
      if @room.update_attributes(params[:bigbluebutton_room])
        message = t('bigbluebutton_rails.rooms.notice.update.success')
        format.html {
          redirect_to params[:redir_url] ||= bigbluebutton_room_path(@room), :notice => message
        }
        format.json { render :json => { :message => message } }
      else
        format.html {
          unless params[:redir_url].blank?
            flash[:error] = t('bigbluebutton_rails.rooms.notice.update.failure')
            redirect_to params[:redir_url]
          else
            render :edit
          end
        }
        format.json { render :json => @room.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    error = false
    begin
      @room.fetch_is_running?
      @room.send_end if @room.is_running?
      message = t('bigbluebutton_rails.rooms.notice.destroy.success')
    rescue BigBlueButton::BigBlueButtonException => e
      error = true
      message = t('bigbluebutton_rails.rooms.notice.destroy.success_with_bbb_error', :error => e.to_s[0..200])
    end

    # TODO: what if it fails?
    @room.destroy

    respond_with do |format|
      format.html {
        flash[:error] = message if error
        redirect_to params[:redir_url] ||= bigbluebutton_rooms_url
      }
      format.json {
        if error
          render :json => { :message => message }, :status => :error
        else
          render :json => { :message => message }
        end
      }
    end
  end

  # Used by logged users to join public rooms.
  def join
    @user_role = bigbluebutton_role(@room)
    if @user_role.nil?
      raise BigbluebuttonRails::RoomAccessDenied.new

    # anonymous users or users with the role :password join through #invite
    elsif bigbluebutton_user.nil? or @user_role == :password
      redirect_to :action => :invite, :mobile => params[:mobile]

    else
      join_internal(bigbluebutton_user.name, @user_role, bigbluebutton_user.id, :join)
    end
  end

  # Used to join private rooms or to invite anonymous users (not logged)
  def invite
    respond_with @room do |format|

      @user_role = bigbluebutton_role(@room)
      if @user_role.nil?
        raise BigbluebuttonRails::RoomAccessDenied.new
      else
        format.html
      end

    end
  end

  # Authenticates an user using name and password passed in the params from #invite
  # Uses params[:id] to get the target room
  def auth
    @room = BigbluebuttonRoom.find_by_param(params[:id]) unless params[:id].blank?
    if @room.nil?
      message = t('bigbluebutton_rails.rooms.errors.auth.wrong_params')
      redirect_to :back, :notice => message
      return
    end

    # gets the user information, given priority to a possible logged user
    name = bigbluebutton_user.nil? ? params[:user][:name] : bigbluebutton_user.name
    id = bigbluebutton_user.nil? ? nil : bigbluebutton_user.id
    # the role: nil means access denied, :password means check the room
    # password, otherwise just use it
    @user_role = bigbluebutton_role(@room)
    if @user_role.nil?
      raise BigbluebuttonRails::RoomAccessDenied.new
    elsif @user_role == :password
      role = @room.user_role(params[:user])
    else
      role = @user_role
    end

    unless role.nil? or name.nil? or name.empty?
      join_internal(name, role, id, :invite)
    else
      flash[:error] = t('bigbluebutton_rails.rooms.errors.auth.failure')
      render :invite, :status => :unauthorized
    end
  end

  # receives :server_id to indicate the server and :meeting to indicate the
  # MeetingID of the meeting that should be joined
  def external
    if params[:meeting].blank?
      message = t('bigbluebutton_rails.rooms.errors.external.blank_meetingid')
      redirect_to params[:redir_url] ||= bigbluebutton_rooms_path, :notice => message
    end
    @room = BigbluebuttonRoom.new(:server => @server, :meetingid => params[:meeting])
  end

  # Authenticates an user using name and password passed in the params from #external
  # Uses params[:meeting] to get the meetingID of the target room
  def external_auth
    # check :meeting and :user
    if !params[:meeting].blank? && !params[:user].blank?
      @server.fetch_meetings
      @room = @server.meetings.select{ |r| r.meetingid == params[:meeting] }.first
      message = t('bigbluebutton_rails.rooms.errors.external.inexistent_meeting') if @room.nil?
    else
      message = t('bigbluebutton_rails.rooms.errors.external.wrong_params')
    end

    unless message.nil?
      @room = nil
      redirect_to :back, :notice => message
      return
    end

    # This is just to check if the room is not blocked, not to get the actual role
    raise BigbluebuttonRails::RoomAccessDenied.new if bigbluebutton_role(@room).nil?

    # if there's a user logged, use his name instead of the name in the params
    name = bigbluebutton_user.nil? ? params[:user][:name] : bigbluebutton_user.name
    id = bigbluebutton_user.nil? ? nil : bigbluebutton_user.id
    role = @room.user_role(params[:user])

    unless role.nil? or name.nil? or name.empty?
      join_internal(name, role, id, :external)
    else
      flash[:error] = t('bigbluebutton_rails.rooms.errors.auth.failure')
      render :external, :status => :unauthorized
    end
  end

  def running
    begin
      @room.fetch_is_running?
    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s[0..200]
      render :json => { :running => "false", :error => "#{e.to_s[0..200]}" }
    else
      render :json => { :running => "#{@room.is_running?}" }
    end
  end

  def end
    error = false
    begin
      @room.fetch_is_running?
      if @room.is_running?
        @room.send_end
        message = t('bigbluebutton_rails.rooms.notice.end.success')
      else
        error = true
        message = t('bigbluebutton_rails.rooms.notice.end.not_running')
      end
    rescue BigBlueButton::BigBlueButtonException => e
      error = true
      message = e.to_s[0..200]
    end

    if error
      respond_with do |format|
        format.html {
          flash[:error] = message
          redirect_to :back
        }
        format.json { render :json => message, :status => :error }
      end
    else
      respond_with do |format|
        format.html {
          redirect_to(params[:redir_url] || bigbluebutton_room_path(@room), :notice => message)
        }
        format.json { render :json => message }
      end
    end

  end

  def join_mobile
    @join_url = join_bigbluebutton_room_url(@room, :mobile => '1')
    @join_url.gsub!(/http:\/\//i, "bigbluebutton://")

    # TODO: we can't use the mconf url because the mobile client scanning the qrcode is not
    # logged. so we are using the full BBB url for now.
    @qrcode_url = @room.join_url(bigbluebutton_user.name, bigbluebutton_role(@room))
    @qrcode_url.gsub!(/http:\/\//i, "bigbluebutton://")
  end

  def fetch_recordings
    error = false

    if @room.server.nil?
      error = true
      message = t('bigbluebutton_rails.rooms.error.fetch_recordings.no_server')
    else
      begin
        # filter only recordings created by this room
        filter = { :meetingID => @room.meetingid }
        @room.server.fetch_recordings(filter)
        message = t('bigbluebutton_rails.rooms.notice.fetch_recordings.success')
      rescue BigBlueButton::BigBlueButtonException => e
        error = true
        message = e.to_s[0..200]
      end
    end

    respond_with do |format|
      format.html {
        flash[error ? :error : :notice] = message
        redirect_to bigbluebutton_room_path(@room)
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

  def recordings
    respond_with(@recordings = @room.recordings)
  end

  protected

  def find_room
    @room = BigbluebuttonRoom.find_by_param(params[:id])
  end

  def find_server
    @server = BigbluebuttonServer.find(params[:server_id])
  end

  def set_request_headers
    unless @room.nil?
      @room.request_headers["x-forwarded-for"] = request.remote_ip
    end
  end

  def join_internal(username, role, id, wait_action)
    begin
      # first check if we have to create the room and if the user can do it
      @room.fetch_is_running?
      unless @room.is_running?
        if bigbluebutton_can_create?(@room, role)
          @room.create_meeting(username, id, request)
        else
          flash[:error] = t('bigbluebutton_rails.rooms.errors.auth.cannot_create')
          render wait_action, :status => :unauthorized
          return
        end
      end

      # room created and running, try to join it
      url = @room.join_url(username, role)
      unless url.nil?
        # change the protocol to join with BBB-Android/Mconf-Mobile if set
        if BigbluebuttonRails::value_to_boolean(params[:mobile])
          url.gsub!(/http:\/\//i, "bigbluebutton://")
        end
        redirect_to(url)
      else
        flash[:error] = t('bigbluebutton_rails.rooms.errors.auth.not_running')
        render wait_action
      end

    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s[0..200]
      redirect_to :back
    end
  end

end
