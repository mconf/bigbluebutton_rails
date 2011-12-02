When /^he should see all available servers in the list$/i do
  # FIXME this is already being checked in "he goes to the servers index page"
  #       any better ideas?
  check_template("servers index")
end

When /^he should see all the information available for this server$/i do
  # FIXME this is already being checked in "he goes to the show server page"
  #       any better ideas?
  check_template("show server")
end
