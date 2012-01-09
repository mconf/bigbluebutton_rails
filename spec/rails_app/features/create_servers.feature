Feature: Create webconference servers
  In order to held webconferences
  One needs to create and configure webconference servers

  Scenario: Access the page to create a new server
    Given an anonymous user
    When he goes to the new server page
    Then he should see the new server page

  Scenario: Register a new server
    Given an anonymous user
    When he goes to the new server page
      And registers a new server
    Then he should see the information about this server

  Scenario: Try to register a server with errors
    Given an anonymous user
    When he goes to the new server page
      And registers a new server with a wrong URL
    Then he should be at the create server URL
      And see the new server page
      And see 1 error in the field "bigbluebutton_server[url]"
