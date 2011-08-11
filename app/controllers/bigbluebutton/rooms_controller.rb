require 'bigbluebutton-api'

class Bigbluebutton::RoomsController < ApplicationController

  before_filter :find_server
  before_filter :find_room, :only => [:show, :edit, :update, :destroy, :join, :invite, :running, :end, :destroy, :end, :join_mobile]
  respond_to :html, :except => :running
  respond_to :json, :only => [:running, :show, :new, :index, :create, :update]
  #respond_to :mobile, :only => [:join]

  def index
    # TODO restrict to rooms belonging to the selected server
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
    @room.server = @server

    if !params[:bigbluebutton_room].has_key?(:meetingid) or
        params[:bigbluebutton_room][:meetingid].blank?
      @room.meetingid = @room.name
    end

    respond_with @room do |format|
      if @room.save
        message = t('bigbluebutton_rails.rooms.notice.create.success')
        format.html {
          params[:redir_url] ||= bigbluebutton_server_room_path(@server, @room)
          redirect_to params[:redir_url], :notice => message
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
    if !params[:bigbluebutton_room].has_key?(:meetingid) or
        params[:bigbluebutton_room][:meetingid].blank?
      params[:bigbluebutton_room][:meetingid] = params[:bigbluebutton_room][:name]
    end

    respond_with @room do |format|
      if @room.update_attributes(params[:bigbluebutton_room])
        message = t('bigbluebutton_rails.rooms.notice.update.success')
        format.html {
          params[:redir_url] ||= bigbluebutton_server_room_path(@server, @room)
          redirect_to params[:redir_url], :notice => message
        }
        format.json { render :json => { :message => message } }
      else
        format.html {
          unless params[:redir_url].blank?
            message = t('bigbluebutton_rails.rooms.notice.update.failure')
            redirect_to params[:redir_url], :error => message
          else
            render :edit
          end
        }
        format.json { render :json => @room.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    # TODO Destroy the room record even if end_meeting failed?

    error = false
    begin
      @room.fetch_is_running?
      @room.send_end if @room.is_running?
    rescue BigBlueButton::BigBlueButtonException => e
      error = true
      message = e.to_s
      # TODO Better error message: "Room destroyed in DB, but not in BBB..."
    end

    @room.destroy

    respond_with do |format|
      format.html {
        flash[:error] = message if error
        params[:redir_url] ||= bigbluebutton_server_rooms_url
        redirect_to params[:redir_url]
      }
      if error
        format.json { render :json => { :message => message }, :status => :error }
      else
        message = t('bigbluebutton_rails.rooms.notice.destroy.success')
        format.json { render :json => { :message => message } }
      end
    end
  end

  # Used by logged users to join public rooms.
  def join
    role = bigbluebutton_role(@room)
    if role.nil?
      raise BigbluebuttonRails::RoomAccessDenied.new

    # anonymous users or users with the role :password join through #invite
    elsif bigbluebutton_user.nil? or role == :password
      redirect_to :action => :invite

    else
      join_internal(bigbluebutton_user.name, role, :join)
    end
  end

  # Used to join private rooms or to invited anonymous users (not logged)
  def invite
    respond_with @room do |format|

      role = bigbluebutton_role(@room)
      if role.nil?
        raise BigbluebuttonRails::RoomAccessDenied.new

      # if there's already a logged user with a role in the room, join through #join
      elsif !bigbluebutton_user.nil? and role != :password
        format.html { redirect_to :action => :join }

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
      redirect_to request.referer, :notice => message
      return
    end

    raise BigbluebuttonRails::RoomAccessDenied.new if bigbluebutton_role(@room).nil?

    # if there's a user logged, use his name instead of the name in the params
    name = bigbluebutton_user.nil? ? params[:user][:name] : bigbluebutton_user.name
    role = @room.user_role(params[:user])

    unless role.nil? or name.nil?
      join_internal(name, role, :invite)
    else
      flash[:error] = t('bigbluebutton_rails.rooms.errors.auth.failure')
      render :invite, :status => :unauthorized
    end
  end

  def external
    if params[:meeting].blank?
      message = t('bigbluebutton_rails.rooms.errors.external.blank_meetingid')
      params[:redir_url] ||= bigbluebutton_server_rooms_path(@server)
      redirect_to params[:redir_url], :notice => message
    end
    @room = BigbluebuttonRoom.new(:meetingid => params[:meeting])
  end

  # Authenticates an user using name and password passed in the params from #external
  # Uses params[:meeting] to get the meetingID of the target room
  def external_auth
    @room = nil
    if !params[:meeting].blank? && !params[:user].blank?
      @server.fetch_meetings
      @room = @server.meetings.select{ |r| r.meetingid == params[:meeting] }.first
    else
      message = t('bigbluebutton_rails.rooms.errors.auth.wrong_params')
      redirect_to request.referer, :notice => message
      return
    end

    # This is just to check if the room is not blocked, not to get the actual role
    raise BigbluebuttonRails::RoomAccessDenied.new if bigbluebutton_role(@room).nil?

    # if there's a user logged, use his name instead of the name in the params
    name = bigbluebutton_user.nil? ? params[:user][:name] : bigbluebutton_user.name
    role = @room.user_role(params[:user])

    unless role.nil? or name.nil?
      @room.fetch_meeting_info
      if @room.is_running?
        join_url = @room.join_url(name, role)
        redirect_to(join_url)
      else
        flash[:error] = t('bigbluebutton_rails.rooms.errors.auth.not_running')
        render :external
      end
    else
      flash[:error] = t('bigbluebutton_rails.rooms.errors.auth.failure')
      render :external, :status => :unauthorized
    end
  end

  def running
    begin
      @room.fetch_is_running?
    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s
      render :json => { :running => "false", :error => "#{e.to_s}" }
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
      message = e.to_s
    end

    if error
      respond_with do |format|
        format.html {
          flash[:error] = message
          redirect_to request.referer
        }
        format.json { render :json => message, :status => :error }
      end
    else
      respond_with do |format|
        format.html {
          redirect_to(bigbluebutton_server_room_path(@server, @room), :notice => message)
        }
        format.json { render :json => message }
      end
    end

  end

  def join_mobile
    @join_url = @room.join_url(bigbluebutton_user.name, bigbluebutton_role(@room))
    @join_url.gsub!("http://", "bigbluebutton://")
  end

  protected

  def find_room
    @room = BigbluebuttonRoom.find_by_param(params[:id])
  end

  def find_server
    if params.has_key?(:server_id)
      @server = BigbluebuttonServer.find_by_param(params[:server_id])
    else
      @server = BigbluebuttonServer.first
    end
  end

  def join_internal(username, role, wait_action)
    begin
      url = @room.perform_join(username, role, request)
      unless url.nil?
        redirect_to(url)
      else
        flash[:error] = t('bigbluebutton_rails.rooms.errors.auth.not_running')
        render wait_action
      end
    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s
      redirect_to request.referer
    end
  end

end
