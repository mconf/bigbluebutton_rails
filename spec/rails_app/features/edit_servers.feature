Feature: Edit webconference servers
  To change the information of a webconference server
  One needs to be able to edit and update the server

  Scenario: Access the page to edit a server
    Given an anonymous user
      And a real server
    When he goes to the edit server page
    Then he should see the edit server page

  Scenario: Edit data in a server
    Given an anonymous user
      And a real server
    When he goes to the edit server page
      And change the server URL to "http://test.com/bigbluebutton/api"
      And clicks in the button to save the server
    Then he should be at the show server URL
      And the server URL should be "http://test.com/bigbluebutton/api"

  Scenario: Try to edit data in a server with incorrect values
    Given an anonymous user
      And a real server
    When he goes to the edit server page
      And change the server URL to "http://test.com/"
      And clicks in the button to save the server
    Then he should be at the update server URL
      And see the edit server page
      And see 1 errors in the field "bigbluebutton_server[url]"
      And the server URL should NOT be "http://test.com/"
