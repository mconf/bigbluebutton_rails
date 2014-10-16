class Bigbluebutton::PlaybackTypesController < ApplicationController
  include BigbluebuttonRails::InternalControllerMethods

  respond_to :html
  respond_to :json
  before_filter :find_playback_type

  def update
    respond_with @playback_type do |format|
      if @playback_type.update_attributes(playback_type_params)
        format.html {
          message = t('bigbluebutton_rails.playback_types.notice.update.success')
          redirect_to_using_params request.referer, :notice => message
        }
        format.json { render :json => true, :status => :ok }
      else
        format.html { redirect_to_params request.referer, :error => @playback_type.errors.full_messages }
        format.json { render :json => @playback_type.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  protected

  def find_playback_type
    @playback_type = BigbluebuttonPlaybackType.find(params[:id])
  end

  def playback_type_params
    unless params[:bigbluebutton_playback_type].nil?
      params[:bigbluebutton_playback_type].permit(*playback_type_allowed_params)
    else
      {}
    end
  end

  def playback_type_allowed_params
    [ :visible ]
  end

end
