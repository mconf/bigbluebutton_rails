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
    error = false
    begin
      if @recording.room and @recording.room.server
        server = @recording.room.server
        server.send_delete_recordings(@recording.recordingid)
      end
      message = t('bigbluebutton_rails.recordings.notice.destroy.success')
    rescue BigBlueButton::BigBlueButtonException => e
      error = true
      message = t('bigbluebutton_rails.recordings.notice.destroy.success_with_bbb_error', :error => e.to_s)
    end

    # TODO: what if it fails?
    @recording.destroy

    respond_with do |format|
      format.html {
        flash[:error] = message if error
        params[:redir_url] ||= bigbluebutton_recordings_url
        redirect_to params[:redir_url]
      }
      format.json {
        if error
         render :json => { :message => message }, :status => :error
        else
          render :json => { :message => message }
        end
      }
    end
  end

  protected

  def find_recording
    @recording = BigbluebuttonRecording.find_by_recordingid(params[:id])
  end

end
