# -*- coding: utf-8 -*-
require 'bigbluebutton_api'

class Bigbluebutton::MeetingsController < ApplicationController
  include BigbluebuttonRails::InternalControllerMethods

  before_filter :find_meeting

  layout :determine_layout

  def determine_layout
    'application'
  end

  def destroy
    @meeting.destroy

    message = t('bigbluebutton_rails.meetings.delete.success')
    redirect_to_using_params_or_back(request.referer, :notice => message)
  end

  def find_meeting
    @meeting ||= BigbluebuttonMeeting.find_by(id: params[:id])
  end
end
