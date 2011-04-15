require 'bigbluebutton-api'

class Bigbluebutton::RoomsController < ApplicationController

  before_filter :find_server
  respond_to :html, :except => :running
  respond_to :json, :only => :running

  def index
    # TODO restrict to rooms belonging to the selected server
    respond_with(@rooms = BigbluebuttonRoom.all)
  end

  def show
    respond_with(@room = BigbluebuttonRoom.find(params[:id]))
  end

  def new
    respond_with(@room = BigbluebuttonRoom.new)
  end

  def edit
    respond_with(@room = BigbluebuttonRoom.find(params[:id]))
  end

  def create
    @room = BigbluebuttonRoom.new(params[:bigbluebutton_room])
    @room.server = @server

    # TODO Generate a random meeting_id everytime a room is created
    if !params[:bigbluebutton_room].has_key?(:meeting_id) or
        params[:bigbluebutton_room][:meeting_id].blank?
      @room.meeting_id = @room.name
    end

    respond_with @room do |format|
      if @room.save
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.create.success')
          redirect_to(bigbluebutton_server_room_path(@server, @room), :notice => message)
        }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @room = BigbluebuttonRoom.find(params[:id])

    if !params[:bigbluebutton_room].has_key?(:meeting_id) or
        params[:bigbluebutton_room][:meeting_id].blank?
      params[:bigbluebutton_room][:meeting_id] = params[:bigbluebutton_room][:name]
    end

    respond_with @room do |format|
      if @room.update_attributes(params[:bigbluebutton_room])
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.update.success')
          redirect_to(bigbluebutton_server_room_path(@server, @room), :notice => message)
        }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @room = BigbluebuttonRoom.find(params[:id])

    # TODO Destroy the room record even if end_meeting failed?

    begin
      @room.fetch_is_running?
      @room.send_end if @room.is_running?
    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s
      # TODO Better error message: "Room destroyed in DB, but not in BBB..."
    end

    @room.destroy
    redirect_to(bigbluebutton_server_rooms_url)
  end

  # Used to join public rooms with a logged user.
  def join
    @room = BigbluebuttonRoom.find(params[:id])

    # private rooms and anonymous users join through #invite
    if @room.private or bigbluebutton_user.nil?
      redirect_to :action => :invite
    else
      join_internal(bigbluebutton_user.name, bigbluebutton_role(@room), :join)
    end
  end

  # Used to join private rooms or to invited anonymous users (not logged)
  def invite
    @room = BigbluebuttonRoom.find(params[:id])

    respond_with @room do |format|

      # A logged user can join a public room without authorization
      if !@room.private and !bigbluebutton_user.nil?
        format.html { redirect_to :action => :join }
      else
        format.html
      end

    end
  end

  def auth
    @room = BigbluebuttonRoom.find(params[:id])

    role = @room.user_role(params[:user])
    unless role.nil?
      join_internal(params[:user][:name], role, :invite)
    else
      flash[:error] = t('bigbluebutton_rails.rooms.error.auth.failure')
      render :action => "invite", :status => :unauthorized
    end
  end

  def running
    @room = BigbluebuttonRoom.find(params[:id])

    begin
      @room.fetch_is_running?
    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s
      render :json => { running: "false", error: "#{e.to_s}" }
      #redirect_to request.referer
    else
      render :json => { running: "#{@room.is_running?}" }
    end

  end

  def end
    @room = BigbluebuttonRoom.find(params[:id])

    begin
      @room.fetch_is_running?
      if @room.is_running?
        @room.send_end
        message = t('bigbluebutton_rails.rooms.notice.end.success')
      else
        message = t('bigbluebutton_rails.rooms.notice.end.not_running')
      end
    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s
      redirect_to request.referer
    else
      redirect_to(bigbluebutton_server_room_path(@server, @room), :notice => message)
    end

  end

  protected

  def find_server
    if params.has_key?(:server_id)
      @server = BigbluebuttonServer.find(params[:server_id])
    else
      @server = BigbluebuttonServer.first
    end
  end

  def join_internal(username, role, wait_action)

    begin
      @room.fetch_is_running?

      # if the current user is a moderator, create the room (if needed)
      # and join it
      if role == :moderator
        @room.send_create unless @room.is_running?
        join_url = @room.join_url(username, role)
        redirect_to(join_url)

      # normal user only joins if the conference is running
      # if it's not, wait for a moderator to create the conference
      else
        if @room.is_running?
          join_url = @room.join_url(username, role)
          redirect_to(join_url)
        else
          flash[:error] = t('bigbluebutton_rails.rooms.error.not_running')
          render :action => wait_action
        end
      end

    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s
      redirect_to request.referer
    end
  end

end
