class Bigbluebutton::PlaybackTypesController < ApplicationController
  include BigbluebuttonRails::InternalControllerMethods

  respond_to :html
  before_action :find_playback_type, only: [:update]

  def update
    respond_with @playback_type do |format|
      if @playback_type.update_attributes(playback_type_params)
        format.html {
          message = t('bigbluebutton_rails.playback_types.notice.update.success')
          redirect_to_using_params request.referer, :notice => message
        }
      else
        format.html {
          flash[:error] = @playback_type.errors.full_messages.join(", ")
          redirect_to_using_params request.referer
        }
      end
    end
  end

  protected

  def find_playback_type
    @playback_type ||= BigbluebuttonPlaybackType.find(params[:id])
  end

  def playback_type_params
    unless params[:bigbluebutton_playback_type].nil?
      params[:bigbluebutton_playback_type].permit(*playback_type_allowed_params)
    else
      {}
    end
  end

  def playback_type_allowed_params
    [ :visible, :default ]
  end

end
