When /^clicks in the link to remove the first server$/i do
  # there's only 1 server created, so only 1 "Destroy" link
  click_link("Destroy")
end

When /^the removed server should not be listed$/i do
  BigbluebuttonServer.find_by_id(@server.id).should be_nil

  # check params that are specific for this server
  doesnt_have_content(@server.name)
  doesnt_have_content(@server.url)
  doesnt_have_content(@server.secret)
  doesnt_have_content(@server.param)
end
