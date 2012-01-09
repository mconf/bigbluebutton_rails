Feature: Create webconference rooms
  In order to held webconferences
  One needs to create and configure webconference rooms

  Scenario: Access the page to create a new room
    Given an anonymous user
    When he goes to the new room page
    Then he should see the new room page

  Scenario: Register a new BigBlueButton room
    Given a real server
    When the user goes to the new room page
      And registers a new room
    Then he should see the information about this room

  Scenario: Try to register a new BigBlueButton room with errors
    Given a real server
    When the user goes to the new room page
      And registers a new room with wrong parameters
    Then he should be at the create room URL
      And see the new room page
      And see 2 errors in the field "bigbluebutton_room[name]"
