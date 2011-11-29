Feature: Join External BigBlueButton Rooms
  In order to join webconferences that were created from another application
  One needs to enter his name and a password

  @mechanize
  Scenario: Joining an external room as moderator (a room that is not in the database)
    Given a user named "test user"
      And a server
      And an external room
    When the user goes to the join external room page for this room
    Then he should see a form to join the external room
      And be able to join the room

  Scenario: Joining an external room as attendee
    Given is pending

  Scenario: Uses the logged user's name as the default name to join an external room
    Given a user named "test user"
      And a server
      And an external room
    When the user goes to the join external room page for this room
    Then he should see a form to join the external room
      And his name should be in the appropriate input

  # TODO: public rooms hide the password
