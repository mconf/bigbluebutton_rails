# -*- coding: utf-8 -*-
require 'bigbluebutton_api'

class Bigbluebutton::Api::RoomsController < ApplicationController
  include BigbluebuttonRails::APIControllerMethods

  skip_before_action :verify_authenticity_token
  before_action :authenticate_api

  before_action :validate_pagination, only: :index

  before_action :find_room, only: [:running, :join]

  before_action :join_user_params, only: :join

  # only for the ones that trigger API calls
  before_action :set_request_headers, only: [:join, :running]
  before_action :set_content_type

  respond_to :json

  def index
    query = BigbluebuttonRoom

    # Search
    search_terms = map_search(params[:filter])
    query = query.search_by_terms(search_terms) unless search_terms.blank?

    # Sort
    sort_str = map_sort(params[:sort], 'name ASC', ['activity', 'name'])
    if sort_str.match(/activity/) # if requested activity ignore the rest
      activity_order = sort_str.match(/activity ASC/) ? 'DESC' : 'ASC' # yes, inverse logic!
      query = query.order_by_activity(activity_order)
    else
      query = query.order(sort_str)
    end

    # Limits and pagination
    limit, offset, page = map_pagination(params[:page], 10)
    query = query.limit(limit).offset(offset)
    @pagination_links = map_pagination_links(page)

    @rooms = query
    respond_with(@rooms)
  end

  def running
    check_is_running
  end

  def join
    return error_room_not_running unless check_is_running

    # map "meta[_-]" to "userdata-"
    options = params.select{ |k,v| k.match(/^meta[-_]/) }
    unless options.blank?
      options = options.map{ |k,v| { k.gsub(/^meta[-_]/, 'userdata-') => v } }.reduce(:merge)
    end

    @url = @room.parameterized_join_url(@user_name, @user_role, nil, options)
  end

  protected

  def find_room
    @room ||= BigbluebuttonRoom.find_by(slug: params[:id])
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
    @room.request_headers["x-forwarded-for"] = request.remote_ip if @room.present?
  end

  def authenticate_api
    authorization = request.headers["Authorization"]
    secret = authorization.gsub(/^Bearer /, '') if authorization.present?
    server_secret = BigbluebuttonRails.configuration.api_secret
    if server_secret != '' &&
       (server_secret.nil? || secret.blank? || secret != server_secret)
      error_forbidden
    end
  end
end
