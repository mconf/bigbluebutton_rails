class Bigbluebutton::RecordingsController < ApplicationController

  respond_to :html
  respond_to :json, :only => [:index, :show, :update, :destroy]
  before_filter :find_recording, :only => [:show, :edit, :update, :destroy]

  def index
    respond_with(@recordings = BigbluebuttonRecording.all)
  end

  def show
    respond_with(@recording)
  end

  def edit
    respond_with(@recording)
  end

  def update
    respond_with @recording do |format|
      if @recording.update_attributes(params[:bigbluebutton_recording])
        format.html {
          message = t('bigbluebutton_rails.recordings.notice.update.success')
          redirect_to(@recording, :notice => message)
        }
        format.json { head :ok }
      else
        format.html { render :edit }
        format.json { render :json => @recording.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @recording.destroy

    respond_with do |format|
      format.html { redirect_to(bigbluebutton_recordings_url) }
      format.json { head :ok }
    end
  end

  protected

  def find_recording
    @recording = BigbluebuttonRecording.find(params[:id])
    # @recording = BigbluebuttonRecording.find_by_param(params[:id])
  end

end
