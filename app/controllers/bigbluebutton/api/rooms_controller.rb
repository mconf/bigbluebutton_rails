# -*- coding: utf-8 -*-
require 'bigbluebutton_api'

class Bigbluebutton::Api::RoomsController < ApplicationController
  include BigbluebuttonRails::InternalControllerMethods

  skip_before_filter :verify_authenticity_token

  before_filter :set_content_type
  before_filter :set_request_headers

  before_filter :find_room, only: [:running, :join]

  before_filter :join_user_params, only: :join

  respond_to :json

  def index
    query = BigbluebuttonRoom

    if params[:sort]
      sort_str = map_sort_string(params[:sort], ['recent', 'name'])
      if sort_str.match(/recent/) # if requested relevance, only it will be used, ignore the rest
        recent_order = sort_str.match(/recent ASC/) ? 'DESC' : 'ASC' # yes, inverse logic!
        query = query.order_by_recent(recent_order)
      else
        query = query.order(sort_str)
      end
    else
      query = query.order('name ASC')
    end

    @rooms = query.all
    respond_with(@rooms)
  end

  def running
    check_is_running
  end

  def join
    error_room_not_running unless check_is_running

    # map "meta[_-]" to "userdata-"
    meta = params.select{ |k,v| k.match(/^meta[-_]/) }
    meta = meta.map{ |k,v| { k.gsub(/^meta[-_]/, 'userdata-') => v } }.reduce(:merge)

    @url = @room.parameterized_join_url(@user_name, @user_role, nil, meta)
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

  def map_sort_string(param, allowed=[])
    param.split(',').inject('') do |memo, obj|
      if obj[0] == '-'
        attr = obj.gsub(/^-/, '')
        order = 'DESC'
      else
        attr = obj
        order = 'ASC'
      end
      if allowed.blank? || allowed.include?(attr)
        memo = "#{memo}," unless memo.blank?
        memo = "#{memo} #{attr} #{order}"
      else
        memo
      end
    end
  end
end
