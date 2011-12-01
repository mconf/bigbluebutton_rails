Feature: Destroy webconference servers
  To remove a webconference server from the list
  One needs to destroy its record

  Scenario: Destroy a stored BigBlueButton server
    Given an anonymous user
      And a server
    When he goes to the servers index page
      And clicks in the link to remove the first server
    Then he should be at the servers index URL
      And the removed server should not be listed
