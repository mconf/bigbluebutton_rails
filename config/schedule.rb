every 30.minutes do
  rake "bigbluebutton_rails:recordings:update"
end

every 30.minutes do
  rake "bigbluebutton_rails:meetings:finish"
end
