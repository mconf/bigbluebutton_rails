Feature: Join webconference rooms
  In order to participate in webconferences
  One needs to join webconference rooms

  # These scenarios are based in the permission defined in the default
  # bigbluebutton_role method:
  # if room.private or bigbluebutton_user.nil?
  #   :password # ask for a password
  # else
  #   :moderator
  # end

  # First we check the behaviour of BigbluebuttonRoom#join and the redirects to
  # BigbluebuttonRoom#invite

  @mechanize
  Scenario: Joining a public room
    Given a user named "test user"
      And a real server
      And a public room in this server
    When the user goes to the join room page
    Then he should join the conference room

  Scenario: Joining a public room as an anonymous user
    Given an anonymous user
      And a real server
      And a public room in this server
    When the user goes to the join room page
    Then he should be at the invite room URL
      And the password field was pre-filled with the attendee password

  Scenario: Joining a private room requires a password
    Given a user named "test user"
      And a real server
      And a private room in this server
    When the user goes to the join room page
    Then he should be redirected to the invite room URL

  @mechanize
  Scenario: Joining a private room as a moderator
    Given a user named "test user"
      And a real server
      And a private room in this server
    When the user goes to the join room page
      And enters his name and the moderator password
      And clicks in the button "Submit"
    Then he should join the conference room

  Scenario: Joining a private room that is NOT running as attendee
    Given a user named "test user"
      And a real server
      And a private room in this server
    When the user goes to the join room page
      And enters his name and the attendee password
      And clicks in the button "Submit"
    Then he should NOT join the conference room
      And should see an error message with the message "The meeting is not running"

  @mechanize @need-bot
  Scenario: Joining a private room that is running as attendee
    Given a user named "test user"
      And a real server
      And a private room in this server
      And a meeting is running in this room
    When the user goes to the join room page
      And enters his name and the attendee password
      And clicks in the button "Submit"
    Then he should join the conference room

  Scenario: Joining a private room without entering a user name
    Given an anonymous user
      And a real server
      And a private room in this server
    When the user goes to the join room page
      And enters only the moderator password
      And clicks in the button "Submit"
    Then he should NOT join the conference room
      And should see an error message with the message "Authentication failure"

  Scenario: Joining a private room without entering a password (wrong password)
    Given an anonymous user
      And a real server
      And a private room in this server
    When the user goes to the join room page
      And enters only the user name
      And clicks in the button "Submit"
    Then he should NOT join the conference room
      And should see an error message with the message "Authentication failure"

  Scenario: Uses the current user's name as the default name to join a room
    Given a user named "test user"
      And a real server
      And a private room in this server
    When the user goes to the join room page
    Then he should see his name in the user name input


  # For the BigbluebuttonRoom#invite action we only check that it can be used by logged
  # or anonymous users. Other cases were already tested above

  @mechanize
  Scenario: A logged user may join the meeting through the invite page
    Given a user named "test user"
      And a real server
      And a public room in this server
    When the user goes to the invite room page (no view check)
    Then he should join the conference room

  @mechanize
  Scenario: An anonymous user may join the meeting through the invite page
    Given an anonymous user
      And a real server
      And a public room in this server
    When the user goes to the invite room page
      And enters his name and the moderator password
      And clicks in the button "Submit"
    Then he should join the conference room
