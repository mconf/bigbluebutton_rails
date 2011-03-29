class Bigbluebutton::RoomsController < ApplicationController

  before_filter :find_server
  respond_to :html

  def index
    respond_with(@rooms = BigbluebuttonRoom.all)
  end

  def show
    respond_with(@room = BigbluebuttonRoom.find(params[:id]))
  end

  def new
    respond_with(@room = BigbluebuttonRoom.new)
  end

  def edit
    respond_with(@room = BigbluebuttonRoom.find(params[:id]))
  end

  def create
    @room = BigbluebuttonRoom.new(params[:bigbluebutton_room])
    @room.server = @server

    respond_with @room do |format|
      if @room.save
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.successfully_created')
          redirect_to(bigbluebutton_server_room_path(@server, @room), :notice => message)
        }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @room = BigbluebuttonRoom.find(params[:id])

    respond_with @room do |format|
      if @room.update_attributes(params[:bigbluebutton_room])
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.successfully_updated')
          redirect_to(bigbluebutton_server_room_path(@server, @room), :notice => message)
        }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @room = BigbluebuttonRoom.find(params[:id])
    @room.destroy

    redirect_to(bigbluebutton_server_rooms_url)
  end

  def join
    @room = BigbluebuttonRoom.find(params[:id])
    role = bigbluebutton_role(@room)

    # if the current user is a moderator, create the room (if needed)
    # and join it
    if role  == :moderator
      bbb_create_room unless bbb_is_meeting_running?
      join_url = bbb_join_url(bigbluebutton_user.name, role)
      redirect_to(join_url)

    # normal user only joins if the conference is running
    # if it's not, wait for a moderator to create the conference
    else
      if bbb_is_meeting_running?
        join_url = bbb_join_url(bigbluebutton_user.name, role)
        redirect_to(join_url)
      else
        render :action => :join_wait
      end
    end

  end

  def join_wait
  end

  private

  def find_server
    @server = BigbluebuttonServer.find(params[:server_id])
  end


  #
  # Functions that directly call BBB API. Prefixed with bbb_
  #

  def bbb_is_meeting_running?
    @server.api.is_meeting_running?(@room.meeting_id)
  end

  def bbb_create_room
    @server.api.create_meeting(@room.meeting_name, @room.meeting_id,
                               @room.moderator_password, @room.attendee_password,
                               @room.welcome_msg)
  end

  def bbb_join_url(username, role)
    if role == :moderator
      @server.api.moderator_url(@room.meeting_id, username,
                                @room.moderator_password)
    else
      @server.api.attendee_url(@room.meeting_id, username,
                               @room.attendee_password)
    end
  end

end
