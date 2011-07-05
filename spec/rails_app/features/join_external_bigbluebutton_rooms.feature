Feature: Join External BigBlueButton Rooms
  In order to join webconferences that were created from another application
  One needs to enter his name and a password

  Scenario: Join an external BigBlueButton room
    Given a user named "test user"
      And a server
      And an external room called "Demo Meeting"
    When the user goes to the join external room page
    Then he should see a form to join an external room
      And be able to join the room
