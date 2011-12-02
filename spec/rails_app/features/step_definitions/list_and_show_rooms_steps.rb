When /^he should see all available rooms in the list$/i do
  # FIXME this is already being checked in "he goes to the rooms index page"
  #       any better ideas?
  check_template("rooms index")
end

When /^he should see all the information available for this room$/i do
  # FIXME this is already being checked in "he goes to the show room page"
  #       any better ideas?
  check_template("show room")
end
