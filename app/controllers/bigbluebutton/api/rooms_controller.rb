# -*- coding: utf-8 -*-
require 'bigbluebutton_api'

class Bigbluebutton::Api::RoomsController < ApplicationController
  include BigbluebuttonRails::APIControllerMethods

  skip_before_filter :verify_authenticity_token

  before_filter :validate_pagination, only: :index

  before_filter :find_room, only: [:running, :join]

  before_filter :join_user_params, only: :join

  before_filter :set_content_type
  before_filter :set_request_headers

  respond_to :json

  def index
    query = BigbluebuttonRoom

    sort_str = map_sort(params[:sort], 'name ASC', ['activity', 'name'])
    # if requested activity, only it will be used, ignore the rest
    if sort_str.match(/activity/)
      activity_order = sort_str.match(/activity ASC/) ? 'DESC' : 'ASC' # yes, inverse logic!
      query = query.order_by_activity(activity_order)
    else
      query = query.order(sort_str)
    end

    # Limits and pagination
    limit, page = map_pagination(params[:page], 10)
    query = query.limit(limit)
    @pagination_links = map_pagination_links(page)

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
    unless meta.blank?
      meta = meta.map{ |k,v| { k.gsub(/^meta[-_]/, 'userdata-') => v } }.reduce(:merge)
    end

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
      return error_invalid_key if @user_role.blank?
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
    self.content_type = 'application/vnd.api+json'
  end

  def set_request_headers
    # TODO: how to do it even if there is no room set?
    if @room.present?
      @room.request_headers["x-forwarded-for"] = request.remote_ip
    end
  end
end
