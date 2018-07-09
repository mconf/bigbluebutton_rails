# -*- coding: utf-8 -*-
require 'bigbluebutton_api'

class Bigbluebutton::MeetingsController < ApplicationController
  include BigbluebuttonRails::InternalControllerMethods

  before_filter :find_meeting

  respond_to :html

  layout :determine_layout

  def determine_layout
    'application'
  end

  def destroy
    error = false
    if @meeting.present?
      begin
        @meeting.room.fetch_is_running?
        @meeting.room.send_end if @meeting.room.is_running?
        message = t('bigbluebutton_rails.meetings.delete.success')
      rescue BigBlueButton::BigBlueButtonException => e
        error = true
        message = t('bigbluebutton_rails.meetings.notice.destroy.success_with_bbb_error', :error => e.to_s[0..200])
      end

      @meeting.destroy

      respond_with do |format|
        format.html {
          flash[:error] = message if error
          redirect_to_using_params_or_back(request.referer, :notice => message)
        }
      end
    else
      message = t('bigbluebutton_rails.meetings.delete.success')
      redirect_to_using_params_or_back(request.referer, :notice => message)
    end
  end

  def find_meeting
    @meeting ||= BigbluebuttonMeeting.find_by(id: params[:id])
  end
end
