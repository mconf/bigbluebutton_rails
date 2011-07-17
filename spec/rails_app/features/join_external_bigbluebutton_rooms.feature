Feature: Join External BigBlueButton Rooms
  In order to join webconferences that were created from another application
  One needs to enter his name and a password

  Scenario: Joining an external BigBlueButton room
    Given a user named "test user"
      And a server
      And an external room
    When the user goes to the join external room page for this room
    Then he should see a form to join the external room
      And be able to join the room

  Scenario: Uses the user name as the default to join a room
    Given a user named "test user"
      And a server
      And an external room
    When the user goes to the join external room page for this room
    Then he should see a form to join the external room
      And his name should be in the appropriate input
