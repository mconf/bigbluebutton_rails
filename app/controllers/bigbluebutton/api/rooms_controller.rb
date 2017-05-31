# -*- coding: utf-8 -*-
require 'bigbluebutton_api'

class Bigbluebutton::Api::RoomsController < ApplicationController
  include BigbluebuttonRails::InternalControllerMethods

  before_filter :set_content_type
  before_filter :set_request_headers

  before_filter :find_room, only: :running

  respond_to :json

  def index
    @rooms ||= BigbluebuttonRoom.all
    respond_with(@rooms)
  end

  def running
    begin
      @room.fetch_is_running?
    rescue BigBlueButton::BigBlueButtonException => e
      @error = e.to_s
      render 'bigbluebutton/api/error'
    end
  end

  protected

  def find_room
    @room ||= BigbluebuttonRoom.find_by(param: params[:id])
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
end
