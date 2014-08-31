# -*- coding: utf-8 -*-
require 'bigbluebutton_api'

class Bigbluebutton::RoomsController < ApplicationController
  include BigbluebuttonRails::InternalControllerMethods

  before_filter :find_room, :except => [:index, :create, :new, :join]

  # set headers only in actions that might trigger api calls
  before_filter :set_request_headers, :only => [:join_mobile, :end, :running, :join, :destroy]

  before_filter :join_check_room, :only => :join
  before_filter :join_user_params, :only => :join
  before_filter :join_check_can_create, :only => :join
  before_filter :join_check_redirect_to_mobile, :only => :join

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
    @room = BigbluebuttonRoom.new(room_params)

    if params[:bigbluebutton_room] and
        (not params[:bigbluebutton_room].has_key?(:meetingid) or
         params[:bigbluebutton_room][:meetingid].blank?)
      @room.meetingid = @room.name
    end

    respond_with @room do |format|
      if @room.save
        message = t('bigbluebutton_rails.rooms.notice.create.success')
        format.html {
          redirect_to_using_params bigbluebutton_room_path(@room), :notice => message
        }
        format.json {
          render :json => { :message => message }, :status => :created
        }
      else
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.create.failure')
          redirect_to_params_or_render :new, :error => message
        }
        format.json { render :json => @room.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_with @room do |format|
      if @room.update_attributes(room_params)
        message = t('bigbluebutton_rails.rooms.notice.update.success')
        format.html {
          redirect_to_using_params bigbluebutton_room_path(@room), :notice => message
        }
        format.json { render :json => { :message => message } }
      else
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.update.failure')
          redirect_to_params_or_render :edit, :error => message
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
        redirect_to_using_params bigbluebutton_rooms_url
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

  # Used to join users into a meeting. Most of the work is done in before filters.
  # Can be called via GET or POST and accepts parameters both in the POST data and URL.
  def join
    join_internal(@user_name, @user_role, @user_id)
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
          redirect_to_using_params :back
        }
        format.json { render :json => message, :status => :error }
      end
    else
      respond_with do |format|
        format.html {
          redirect_to_using_params bigbluebutton_room_path(@room), :notice => message
        }
        format.json { render :json => message }
      end
    end

  end

  def join_mobile
    filtered_params = select_params_for_join_mobile(params.clone)
    @join_mobile = join_bigbluebutton_room_url(@room, filtered_params.merge({:auto_join => '1' }))
    @join_desktop = join_bigbluebutton_room_url(@room, filtered_params.merge({:desktop => '1' }))
  end

  def fetch_recordings
    error = false

    if @room.server.nil?
      error = true
      message = t('bigbluebutton_rails.rooms.errors.fetch_recordings.no_server')
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
        redirect_to_using_params bigbluebutton_room_path(@room)
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

  def recordings
    respond_with(@recordings = @room.recordings)
  end

  protected

  def find_room
    @room = BigbluebuttonRoom.find_by_param(params[:id])
  end

  def set_request_headers
    unless @room.nil?
      @room.request_headers["x-forwarded-for"] = request.remote_ip
    end
  end

  def join_check_room
    @room = BigbluebuttonRoom.find_by_param(params[:id]) unless params[:id].blank?
    if @room.nil?
      message = t('bigbluebutton_rails.rooms.errors.join.wrong_params')
      redirect_to :back, :notice => message
    end
  end

  # Checks the parameters received when calling `join` and sets them in variables to
  # be accessed by other methods. Sets the user's name, id and role. Gives priority to
  # a logged user over the information provided in the params.
  def join_user_params
    # gets the user information, given priority to a possible logged user
    if bigbluebutton_user.nil?
      @user_name = params[:user].blank? ? nil : params[:user][:name]
      @user_id = nil
    else
      @user_name = bigbluebutton_user.name
      @user_id = bigbluebutton_user.id
    end

    # the role: nil means access denied, :key means check the room
    # key, otherwise just use it
    @user_role = bigbluebutton_role(@room)
    if @user_role.nil?
      raise BigbluebuttonRails::RoomAccessDenied.new
    elsif @user_role == :key
      @user_role = @room.user_role(params[:user])
    end

    if @user_role.nil? or @user_name.blank?
      flash[:error] = t('bigbluebutton_rails.rooms.errors.join.failure')
      redirect_to_on_join_error
    end
  end

  # Aborts and redirects to an error if the user can't create a meeting in
  # the room and it needs to be created.
  def join_check_can_create
    begin
      unless @room.fetch_is_running?
        unless bigbluebutton_can_create?(@room, @user_role)
          flash[:error] = t('bigbluebutton_rails.rooms.errors.join.cannot_create')
          redirect_to_on_join_error
        end
      end
    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s[0..200]
      redirect_to_on_join_error
    end
  end

  # If the user called the join from a mobile device, he will be redirected to
  # an intermediary page with information about the mobile client. A few flags set
  # in the params can override this behavior and skip this intermediary page.
  def join_check_redirect_to_mobile
    if browser.mobile? &&
        !BigbluebuttonRails::value_to_boolean(params[:auto_join]) &&
        !BigbluebuttonRails::value_to_boolean(params[:desktop])

      # since we're redirecting to an intermediary page, we set in the params the params
      # we received, including the referer, so we can go back to the previous page if needed
      filtered_params = select_params_for_join_mobile(params.clone)
      begin
        filtered_params[:redir_url] = Addressable::URI.parse(request.env["HTTP_REFERER"]).path
      rescue
      end

      redirect_to join_mobile_bigbluebutton_room_path(@room, filtered_params)
    end
  end

  # Selects the params from `params` that should be passed in a redirect to `join_mobile` and
  # adds new parameters that might be needed.
  def select_params_for_join_mobile(params)
    params.blank? ? {} : params.slice("user", "redir_url")
  end

  # Default method to redirect after an error in the action `join`.
  def redirect_to_on_join_error
    redirect_to_using_params_or_back(invite_bigbluebutton_room_path(@room))
  end

  # The internal process to join a meeting.
  def join_internal(username, role, id)
    begin
      # first check if we have to create the room and if the user can do it
      unless @room.fetch_is_running?
        if bigbluebutton_can_create?(@room, role)
          user_opts = bigbluebutton_create_options(@room)
          @room.create_meeting(bigbluebutton_user, request, user_opts)
        else
          flash[:error] = t('bigbluebutton_rails.rooms.errors.join.cannot_create')
          redirect_to_on_join_error
          return
        end
      end

      # gets the token with the configurations for this user/room
      token = @room.fetch_new_token
      options = if token.nil? then {} else { :configToken => token } end

      options.merge!({:createTime => @room.create_time}) unless @room.create_time.blank?

      # room created and running, try to join it
      url = @room.join_url(username, role, nil, options)
      unless url.nil?

        # change the protocol to join with a mobile device
        if browser.mobile? && !BigbluebuttonRails::value_to_boolean(params[:desktop])
          url.gsub!(/^[^:]*:\/\//i, "bigbluebutton://")
        end

        # enqueue an update in the meetings for later on
        # note: this is the only update that is not in the model, but has to be here
        # because the model doesn't know when a user joined a room
        Resque.enqueue(::BigbluebuttonMeetingUpdater, @room.id, 15.seconds)

        redirect_to url
      else
        flash[:error] = t('bigbluebutton_rails.rooms.errors.join.not_running')
        redirect_to_on_join_error
      end

    rescue BigBlueButton::BigBlueButtonException => e
      flash[:error] = e.to_s[0..200]
      redirect_to_on_join_error
    end
  end

  def room_params
    unless params[:bigbluebutton_room].nil?
      params[:bigbluebutton_room].permit(*room_allowed_params)
    else
      {}
    end
  end

  def room_allowed_params
    [ :name, :server_id, :meetingid, :attendee_key, :moderator_key, :welcome_msg,
      :private, :logout_url, :dial_number, :voice_bridge, :max_participants, :owner_id,
      :owner_type, :external, :param, :record_meeting, :duration, :default_layout, :presenter_share_only,
      :auto_start_video, :auto_start_audio, :metadata_attributes => [ :id, :name, :content, :_destroy, :owner_id ] ]
  end
end
