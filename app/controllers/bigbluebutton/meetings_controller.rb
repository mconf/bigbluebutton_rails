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
    if @meeting.ended?
      if @meeting.destroy
        respond_with do |format|
          format.html {
            flash[:success] = t('bigbluebutton_rails.meetings.delete.success')
            redirect_to_using_params_or_back(request.referer)
          }
        end
      else
        flash[:error] = t('bigbluebutton_rails.meetings.notice.destroy.error_destroy')
        redirect_to_using_params_or_back(request.referer)
      end
    else
      flash[:error] = t('bigbluebutton_rails.meetings.notice.destroy.running.not_ended')
      redirect_to_using_params_or_back(request.referer)
    end
  end

  def find_meeting
    @meeting ||= BigbluebuttonMeeting.find_by(id: params[:id])
  end

  def update
    respond_with @meeting do |format|
      if @meeting.update_attributes(meeting_params)
        format.html {
          message = t('bigbluebutton_rails.recordings.notice.update.success')
          redirect_to_using_params @meeting, :notice => message
        }
      else
        format.html { redirect_to_params_or_render :edit }
      end
    end
  end

end
