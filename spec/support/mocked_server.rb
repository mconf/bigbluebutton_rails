def mock_server_and_api
  @api_mock = mock(BigBlueButton::BigBlueButtonApi)
  @server_mock = mock_model(BigbluebuttonServer)
  @server_mock.stub(:api) { @api_mock }
  BigbluebuttonServer.stub(:find) { @server_mock }
  BigbluebuttonServer.stub(:find_by_param) { @server_mock }
  unless room.nil?
    room.stub(:server) { @server_mock }
    BigbluebuttonRoom.stub(:find_by_param) { room }
    BigbluebuttonRoom.stub(:find) { room }
  end
end

def mocked_server
  @server_mock
end

def mocked_api
  @api_mock
end
