Feature: Edit webconference rooms
  To change the information of a webconference rooms
  One needs to be able to edit and update the room

  Scenario: Access the page to edit a room
    Given an anonymous user
      And a real server
      And a room in this server
    When he goes to the edit room page
    Then he should see the edit room page

  Scenario: Edit data in a BigBlueButton room
    Given an anonymous user
      And a real server
      And a room in this server
    When he goes to the edit room page
      And change the room name to "Anything different"
      And clicks in the button to save the room
    Then he should be at the show room URL
      And the room name should be "Anything different"

  Scenario: Try to edit data in a BigBlueButton room with incorrect values
    Given an anonymous user
      And a real server
      And a room in this server
    When he goes to the edit room page
      And change the room name to ""
      And clicks in the button to save the room
    Then he should be at the update room URL
      And see the edit room page
      And see 2 errors in the field "bigbluebutton_room[name]"
      And the room name should NOT be "Anything different"
