When /^he should see the QR code and a link to join using a mobile device$/i do
  check_template("mobile join", { :room => @room })
end
