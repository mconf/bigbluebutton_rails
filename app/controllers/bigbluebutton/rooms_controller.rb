class Bigbluebutton::RoomsController < ApplicationController

  before_filter :find_server

  def index
    @rooms = BigbluebuttonRoom.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rooms }
    end
  end

  def show
    @room = BigbluebuttonRoom.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @room }
    end
  end

  def new
    @room = BigbluebuttonRoom.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @room }
    end
  end

  def edit
    @room = BigbluebuttonRoom.find(params[:id])
  end

  def create
    @room = BigbluebuttonRoom.new(params[:bigbluebutton_room])
    @room.server = @server

    respond_to do |format|
      if @room.save
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.successfully_created')
          redirect_to(bigbluebutton_server_room_path(@server, @room), :notice => message)
        }
        format.xml  { render :xml => @room, :status => :created, :location => @room }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @room.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @room = BigbluebuttonRoom.find(params[:id])

    respond_to do |format|
      if @room.update_attributes(params[:bigbluebutton_room])
        format.html {
          message = t('bigbluebutton_rails.rooms.notice.successfully_updated')
          redirect_to(bigbluebutton_server_room_path(@server, @room), :notice => message)
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @room.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @room = BigbluebuttonRoom.find(params[:id])
    @room.destroy

    respond_to do |format|
      format.html { redirect_to(bigbluebutton_server_rooms_url) }
      format.xml  { head :ok }
    end
  end

  def join
    @room = BigbluebuttonRoom.find(params[:id])

    unless bbb_is_meeting_running?
      bbb_create_room
    end

#    unless running
#      if mod_permission
#        create_room
#      else
#        redir_to_wait_for_mod
#      end
#    end
#    join

    join_url = bbb_join_url(bigbluebutton_user.name)

    respond_to do |format|
      format.html { redirect_to(join_url) }
      format.xml  { head :ok }
    end
  end

  private

  def find_server
    @server = BigbluebuttonServer.find(params[:server_id])
  end

  def bbb_is_meeting_running?
    @server.api.is_meeting_running?(@room.meeting_id)
  end

  def bbb_create_room
    @server.api.create_meeting(@room.meeting_name, @room.meeting_id,
                               @room.moderator_password, @room.attendee_password,
                               @room.welcome_msg)
  end

  def bbb_join_url(username)
    @server.api.moderator_url(@room.meeting_id,
                              username,
                              @room.moderator_password)
  end

end
