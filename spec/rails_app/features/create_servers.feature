Feature: Create webconference servers
  In order to held webconferences
  One needs to create and configure webconference servers

  Scenario: Register a new BigBlueButton server
    Given an anonymous user
    When he goes to the new server page
      And registers a new server
    Then he should see the information about this server

  Scenario: Try to register a BigBlueButton server with errors
    Given an anonymous user
    When he goes to the new server page
      And registers a new server with a wrong URL
    Then he should be at the create server URL
      And see the new server page
      And see 1 error in the field "bigbluebutton_server[url]"
