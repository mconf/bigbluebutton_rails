require 'bigbluebutton-api'

class Bigbluebutton::RoomsController < ApplicationController

  before_filter :find_server
  respond_to :html, :except => :running
  respond_to :json, :only => [:running, :show, :new, :index, :create, :update, :end, :destroy]

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

    # TODO Generate a random meetingid everytime a room is created
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
        format.json { render :json => message, :status => :created }
      else
        format.html {
          unless params[:redir_url].blank?
            message = t('bigbluebutton_rails.rooms.notice.create.failure')
            redirect_to params[:redir_url], :error => message
          else
            render :action => "new"
          end
        }
        format.json { render :json => @room.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @room = BigbluebuttonRoom.find(params[:id])

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
        format.json { render :json => message }
      else
        format.html {
          unless params[:redir_url].blank?
            message = t('bigbluebutton_rails.rooms.notice.update.failure')
            redirect_to params[:redir_url], :error => message
          else
            render :action => "edit"
          end
        }
        format.json { render :json => @room.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @room = BigbluebuttonRoom.find(params[:id])

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
        format.json { render :json => message, :status => :error }
      else
        message = t('bigbluebutton_rails.rooms.notice.destroy.success')
        format.json { render :json => message }
      end
    end
  end

  # Used by logged users to join public rooms.
  def join
    @room = BigbluebuttonRoom.find(params[:id])

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
    @room = BigbluebuttonRoom.find(params[:id])

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
  def auth
    @room = BigbluebuttonRoom.find(params[:id])

    raise BigbluebuttonRails::RoomAccessDenied.new if bigbluebutton_role(@room).nil?

    # if there's a user logged, use his name instead of the name in the params
    name = bigbluebutton_user.nil? ? params[:user][:name] : bigbluebutton_user.name
    role = @room.user_role(params[:user])

    unless role.nil? or name.nil?
      join_internal(name, role, :invite)
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
      render :json => { :running => "false", :error => "#{e.to_s}" }
    else
      render :json => { :running => "#{@room.is_running?}" }
    end

  end

  def end
    @room = BigbluebuttonRoom.find(params[:id])

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
    @room = BigbluebuttonRoom.find(params[:id])
    @join_url = @room.join_url(bigbluebutton_user.name, bigbluebutton_role(@room))
    @join_url.gsub!("http://", "bigbluebutton://")
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
          flash[:error] = t('bigbluebutton_rails.rooms.error.auth.not_running')
          render :action => wait_action
        end
      end

    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s
      redirect_to request.referer
    end
  end

end
