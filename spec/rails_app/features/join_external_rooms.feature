Feature: Join external webconference rooms
  In order to join webconferences that were created from another application
  One needs to enter his name and a password, that will define his role

  @mechanize
  Scenario: Joining an external room as moderator (a room that is not in the database)
    Given an anonymous user
      And a real server
      And an external room in this server
    When the user goes to the join external room page
      And enters his name and the moderator password
      And clicks in the button "Submit"
    Then he should join the conference room

  Scenario: Joining an external room that is NOT running as attendee
    Given an anonymous user
      And a real server
      And an external room in this server
    When the user goes to the join external room page
      And enters his name and the attendee password
      And clicks in the button "Submit"
    Then he should NOT join the conference room
      And should see an error message with the message "You don't have permissions to start this meeting"

  @mechanize @need-bot
  Scenario: Joining an external room that is running as attendee
    Given an anonymous user
      And a real server
      And an external room in this server with a meeting running
    When the user goes to the join external room page
      And enters his name and the attendee password
      And clicks in the button "Submit"
    Then he should join the conference room

  Scenario: Joining an external room without entering a user name
    Given an anonymous user
      And a real server
      And an external room in this server
    When the user goes to the join external room page
      And enters only the moderator password
      And clicks in the button "Submit"
    Then he should NOT join the conference room
      And should see an error message with the message "Authentication failure"

  Scenario: Joining an external room without entering a password (wrong password)
    Given an anonymous user
      And a real server
      And an external room in this server
    When the user goes to the join external room page
      And enters only the user name
      And clicks in the button "Submit"
    Then he should NOT join the conference room
      And should see an error message with the message "Authentication failure"

  Scenario: Uses the current user's name as the default name to join an external room
    Given a user named "test user"
      And a real server
      And an external room in this server
    When the user goes to the join external room page
    Then he should see his name in the user name input
