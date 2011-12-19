When /^he should see the QR code and a link to join using a mobile device$/i do
  # FIXME this is already being checked in "he goes to the mobile join page"
  #       any better ideas?
  check_template("mobile join")
end
