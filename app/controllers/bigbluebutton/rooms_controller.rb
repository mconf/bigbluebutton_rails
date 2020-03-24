# -*- coding: utf-8 -*-
require 'bigbluebutton_api'

class Bigbluebutton::RoomsController < ApplicationController
  include BigbluebuttonRails::InternalControllerMethods

  before_action :find_room, :except => [:index, :create, :new, :join]

  # set headers only in actions that might trigger api calls
  before_action :set_request_headers, :only => [:join_mobile, :end, :running, :join, :destroy]

  before_action :join_check_room, :only => :join
  before_action :join_user_params, :only => :join
  before_action :join_check_can_create, :only => :join
  before_action :join_check_redirect_to_mobile, :only => :join

  respond_to :html, except: :running
  respond_to :json, only: :running

  def index
    @rooms ||= BigbluebuttonRoom.all
    respond_with(@rooms)
  end

  def show
    respond_with(@room)
  end

  def new
    @room ||= BigbluebuttonRoom.new
    respond_with(@room)
  end

  def edit
    respond_with(@room)
  end

  def create
    @room ||= BigbluebuttonRoom.new(room_params)

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
      else
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.create.failure')
          redirect_to_params_or_render :new, :error => message
        }
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
      else
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.update.failure')
          redirect_to_params_or_render :edit, :error => message
        }
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
      info = @room.fetch_meeting_info
      render :json => { :running => "#{@room.is_running?}", :participants_qty => info}
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
      end
    else
      respond_with do |format|
        format.html {
          redirect_to_using_params bigbluebutton_room_path(@room), :notice => message
        }
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

    begin
      result = @room.fetch_recordings
      if result
        message = t('bigbluebutton_rails.rooms.notice.fetch_recordings.success')
      else
        error = true
        message = t('bigbluebutton_rails.rooms.errors.fetch_recordings.no_server')
      end
    rescue BigBlueButton::BigBlueButtonException => e
      error = true
      message = e.to_s[0..200]
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
    @recordings ||= @room.recordings
    respond_with(@recordings)
  end

  def generate_dial_number
    pattern = params[:pattern].blank? ? nil : params[:pattern]
    if @room.generate_dial_number!(pattern)
      message = t('bigbluebutton_rails.rooms.notice.generate_dial_number.success')
      respond_with do |format|
        format.html { redirect_to_using_params :back, notice: message }
      end
    else
      message = t('bigbluebutton_rails.rooms.errors.generate_dial_number.not_unique')
      respond_with do |format|
        format.html {
          flash[:error] = message
          redirect_to_using_params :back
        }
      end
    end
  end

  protected

  def find_room
    @room ||= BigbluebuttonRoom.find_by(slug: params[:id])
  end

  def set_request_headers
    unless @room.nil?
      @room.request_headers["x-forwarded-for"] = request.remote_ip
    end
  end

  def join_check_room
    @room ||= BigbluebuttonRoom.find_by(slug: params[:id]) unless params[:id].blank?
    if @room.nil?
      flash[:notice] = t('bigbluebutton_rails.rooms.errors.join.wrong_params')
      redirect_back(fallback_location: root_path)
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

  # If the user called the join from a mobile device, he will be redirected to
  # an intermediary page with information about the mobile client. A few flags set
  # in the params can override this behavior and skip this intermediary page.
  def join_check_redirect_to_mobile
    return if !BigbluebuttonRails.use_mobile_client?(browser) ||
              BigbluebuttonRails.value_to_boolean(params[:auto_join]) ||
              BigbluebuttonRails.value_to_boolean(params[:desktop])

    # since we're redirecting to an intermediary page, we set in the params the params
    # we received, including the referer, so we can go back to the previous page if needed
    filtered_params = select_params_for_join_mobile(params.clone)
    begin
      filtered_params[:redir_url] = Addressable::URI.parse(request.env["HTTP_REFERER"]).path
    rescue
    end

    redirect_to join_mobile_bigbluebutton_room_path(@room, filtered_params)
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
          if @room.create_meeting(bigbluebutton_user, request)
            logger.info "Meeting created: id: #{@room.meetingid}, name: #{@room.name}, created_by: #{username}, time: #{Time.now.iso8601}"
          end
        else
          flash[:error] = t('bigbluebutton_rails.rooms.errors.join.cannot_create')
          redirect_to_on_join_error
          return
        end
      end

      # room created and running, try to join it
      url = @room.parameterized_join_url(username, role, id, {}, bigbluebutton_user)

      unless url.nil?

        # change the protocol to join with a mobile device
        if BigbluebuttonRails.use_mobile_client?(browser) &&
           !BigbluebuttonRails.value_to_boolean(params[:desktop])
          url.gsub!(/^[^:]*:\/\//i, "bigbluebutton://")
        end

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
    [ :name, :meetingid, :attendee_key, :moderator_key, :welcome_msg,
      :private, :logout_url, :dial_number, :voice_bridge, :max_participants, :owner_id,
      :owner_type, :external, :slug, :record_meeting, :duration, :default_layout, :presenter_share_only,
      :auto_start_video, :auto_start_audio, :background,
      :moderator_only_message, :auto_start_recording, :allow_start_stop_recording,
      :metadata_attributes => [ :id, :name, :content, :_destroy, :owner_id ] ]
  end
end
