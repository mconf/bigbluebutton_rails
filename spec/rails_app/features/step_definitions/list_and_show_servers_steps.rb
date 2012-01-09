When /^he should see all available servers in the list$/i do
  check_template("servers index")
end

When /^he should see all the information available for this server$/i do
  check_template("show server", { :server => @server })
end
