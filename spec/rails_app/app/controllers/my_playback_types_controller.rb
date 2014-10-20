class MyPlaybackTypesController < ApplicationController
  respond_to :html

  def index
    respond_with(@playback_types = BigbluebuttonPlaybackType.all)
  end
end
