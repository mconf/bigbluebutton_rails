def mock_server_and_api
  @api_mock = mock(BigBlueButton::BigBlueButtonApi)
  @server_mock = mock_model(BigbluebuttonServer)
  @server_mock.stub(:api).and_return(@api_mock)
  BigbluebuttonServer.stub(:find).and_return(@server_mock)
  BigbluebuttonServer.stub(:find_by_param).and_return(@server_mock)
end

def mocked_server
  @server_mock
end

def mocked_api
  @api_mock
end
