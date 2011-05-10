# Used to store the attendees of a meeting as returned by BigBlueButton in
# <tt>get_meeting_info</tt>.
class BigbluebuttonAttendee

  attr_accessor :user_id, :full_name, :role

  def from_hash(hash)
    self.user_id = hash[:userID].to_s
    self.full_name = hash[:fullName].to_s
    self.role = hash[:role].to_s.downcase == "moderator" ? :moderator : :attendee
  end

  def ==(other)
    r = true
    [:user_id, :full_name, :role].each do |param|
      r = r && self.send(param) == other.send(param)
    end
    r
  end

end
