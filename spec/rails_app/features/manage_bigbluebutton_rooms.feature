Feature: Manage BigBlueButton rooms
  In order to held webconferences
  One needs to be able to create and manage BigBlueButton rooms

  Scenario: Register a new BigBlueButton room
    Given a BigBlueButton server
    When the user goes to the new BigBlueButton room page
      And registers a new BigBlueButton room
    Then he should see the information about this room
