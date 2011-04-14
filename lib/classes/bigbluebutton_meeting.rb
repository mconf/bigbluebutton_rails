# Used to store the meetings of a server as returned by BigBlueButton in
# <tt>get_meetings</tt>.
class BigbluebuttonMeeting

  attr_accessor :running, :has_been_forcibly_ended, :room

  def from_hash(hash)
    self.running = hash[:running].downcase == "true"
    self.has_been_forcibly_ended = hash[:hasBeenForciblyEnded].downcase == "true"
  end

  def ==(other)
    r = true
    [:running, :has_been_forcibly_ended, :room].each do |param|
      r = r && self.send(param) == other.send(param)
    end
    r
  end

end
