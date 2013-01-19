class FrontpageController < ApplicationController
  def show
    @servers = BigbluebuttonServer.all
    @rooms = BigbluebuttonRoom.all
    @recordings = BigbluebuttonRecording.all
  end
end
