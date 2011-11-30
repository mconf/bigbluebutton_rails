Feature: Create webconference rooms
  In order to held webconferences
  One needs to create and configure webconference rooms

  Scenario: Register a new BigBlueButton room
    Given a server
    When the user goes to the new room page
      And registers a new room
    Then he should see the information about this room
