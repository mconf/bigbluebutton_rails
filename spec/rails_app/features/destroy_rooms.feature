Feature: Destroy webconference rooms
  To remove a webconference room from a server
  One needs to destroy its record

  Scenario: Destroy a stored BigBlueButton server
    Given an anonymous user
      And a real server
      And a room in this server
    When he goes to the rooms index page
      And clicks in the link to remove the first room
    Then he should be at the rooms index URL
      And the removed room should not be listed
