Feature: List and show webconference servers
  To view information of a webconference server
  One needs to see the server in a list of servers
    and see all the information it has stored

  Scenario: View the list of BigBlueButton servers
    Given an anonymous user
      And 3 servers
    When he goes to the servers index page
    Then he should see all available servers in the list

  Scenario: View all information of a BigBlueButton server
    Given an anonymous user
      And a real server
    When he goes to the show server page
    Then he should see all the information available for this server
