require 'spec_helper'

describe BigbluebuttonMeetingUpdater do
  it "waits the amount of time specified before starting"
  it "calls fetch_meeting_info in the target room"
  it "calls finish_meetings if fetch_meeting_info throws an exception"
  it "calls update_current_meetings if fetch_meeting_info is successful"
  it "doesn't break if the room is not found"
end
