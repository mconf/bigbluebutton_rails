# -*- coding: utf-8 -*-
require 'bigbluebutton_api'

class Bigbluebutton::Api::RoomsController < ApplicationController
  include BigbluebuttonRails::InternalControllerMethods

  skip_before_filter :verify_authenticity_token

  before_filter :set_content_type
  before_filter :set_request_headers

  before_filter :find_room, only: [:running, :join]

  # join sequence
  before_filter :join_user_params, only: :join
  # before_filter :join_check_can_create, only: :join
  # before_filter :join_check_redirect_to_mobile, only: :join

  respond_to :json

  def index
    @rooms ||= BigbluebuttonRoom.all
    respond_with(@rooms)
  end

  def running
    check_is_running
  end

  def join
    error_room_not_running unless check_is_running
    @url = @room.parameterized_join_url(@user_name, @user_role, nil)
  end

  protected

  def find_room
    @room ||= BigbluebuttonRoom.find_by(param: params[:id])
    error_room_not_found if @room.nil?
  end

  def join_user_params
    if BigbluebuttonRails.configuration.guest_support
      guest_role = :guest
    else
      guest_role = :attendee
    end

    @user_name = params[:name]
    return error_missing_params if @user_name.blank?

    if @room.private
      key = params[:key]
      return error_missing_params if key.blank?
      @user_role = @room.user_role(key)
    else
      @user_role = guest_role
    end
  end

  def check_is_running
    begin
      @room.fetch_is_running?
    rescue StandardError => e
      @errors = [BigbluebuttonRails::APIError.new(e.to_s, 500)]
      render 'bigbluebutton/api/error'
    end
    @room.is_running?
  end

  def set_content_type
    self.content_type = 'application/vnd.api+json; charset=utf-8'
  end

  def set_request_headers
    # TODO: how to do it even if there is no room set?
    unless @room.nil?
      @room.request_headers["x-forwarded-for"] = request.remote_ip
    end
  end

  def error_room_not_found
    msg = t('bigbluebutton_rails.api.rooms.room_not_found.msg')
    title = t('bigbluebutton_rails.api.rooms.room_not_found.title')
    @errors = [BigbluebuttonRails::APIError.new(msg, 400, title)]
    render 'bigbluebutton/api/error'
  end

  def error_room_not_running
    msg = t('bigbluebutton_rails.api.rooms.room_not_running.msg')
    title = t('bigbluebutton_rails.api.rooms.room_not_running.title')
    @errors = [BigbluebuttonRails::APIError.new(msg, 400, title)]
    render 'bigbluebutton/api/error'
  end

  def error_missing_params
    msg = t('bigbluebutton_rails.api.rooms.missing_params.msg')
    title = t('bigbluebutton_rails.api.rooms.missing_params.title')
    @errors = [BigbluebuttonRails::APIError.new(msg, 400, title)]
    render 'bigbluebutton/api/error'
  end
end
