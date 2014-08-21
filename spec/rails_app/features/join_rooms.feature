Feature: Join webconference rooms
  In order to participate in webconferences
  One needs to join webconference rooms

  # These scenarios are based in the permission defined in the default
  # bigbluebutton_role method:
  # if room.private or bigbluebutton_user.nil?
  #   :key # ask for a key
  # else
  #   :moderator
  # end

  # First the scenarios for BigbluebuttonRoom#join (and the redirects to
  # BigbluebuttonRoom#invite)

  @mechanize
  Scenario: Joining a public room
    Given a user named "test user"
      And a real server
      And a public room in this server
    When the user goes to the join room page
    Then he should join the conference room

  Scenario: Joining a private room requires a key
    Given a user named "test user"
      And a real server
      And a private room in this server
    When the user goes to the join room page
    Then he should be redirected to the invite room URL
      And he should see the invite room page

  @mechanize
  Scenario: Joining a private room as a moderator
    Given a user named "test user"
      And a real server
      And a private room in this server
    When the user goes to the join room page
      And enters his name and the moderator key
      And clicks in the button "Submit"
    Then he should join the conference room

  Scenario: Joining a private room that is NOT running as attendee
    Given a user named "test user"
      And a real server
      And a private room in this server
    When the user goes to the join room page
      And enters his name and the attendee key
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
      And enters his name and the attendee key
      And clicks in the button "Submit"
    Then he should join the conference room

  Scenario: Joining a private room without entering a user name
    Given an anonymous user
      And a real server
      And a private room in this server
    When the user goes to the join room page
      And enters only the moderator key
      And clicks in the button "Submit"
    Then he should NOT join the conference room
      And should see an error message with the message "Authentication failure"

  Scenario: Joining a private room without entering a key (wrong key)
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


  # Scenarios for BigbluebuttonRoom#invite

  # The pre-filling depends on the role of the user, that's defined
  # by bigbluebutton_role(), see the comment on the top of this file.

  Scenario: The invite view shows a link to join from a mobile device when joining from a desktop
    Given a user named "test user"
      And a real server
      And a public room in this server
    When the user goes to the invite room page
    Then he should see a link to join the conference from a mobile device

  # Test the invite view with a user logged

  Scenario: The invite page is pre-filled with the user name and moderator key
    Given a user named "test user"
      And a real server
      # Public room = user is a moderator
      And a public room in this server
    When the user goes to the invite room page (no view check)
    Then he should be at the invite room URL
      And the read-only name field was pre-filled with "test user"
      And the read-only key field was pre-filled with the moderator key

  Scenario: The invite page is pre-filled with the user name only
    Given a user named "test user"
      And a real server
      # Private room = ask for a key
      And a private room in this server
    When the user goes to the invite room page (no view check)
    Then the read-only name field was pre-filled with "test user"
      And the key field was NOT pre-filled

  # Test the invite view without a user logged

  Scenario: The invite page is not pre-filled when there's no user logged
    Given an anonymous user
      And a real server
      And a public room in this server
    When the user goes to the invite room page
    Then the name field was NOT pre-filled
      And the key field was NOT pre-filled

  # Test if the user can actually join the conference

  @mechanize
  Scenario: A logged user may join the meeting using the invite page
    Given a user named "test user"
      And a real server
      And a public room in this server
    When the user goes to the invite room page
      And clicks in the button "Submit"
    Then he should join the conference room

  @mechanize
  Scenario: An anonymous user may join the meeting using the invite page
    Given an anonymous user
      And a real server
      And a public room in this server
    When the user goes to the invite room page
      And enters his name and the moderator key
      And clicks in the button "Submit"
    Then he should join the conference room

  # Tests when the user is accessing from a mobile client

  Scenario: Accessing from a mobile device the invite form should point to the join with mobile=true
    Given a user named "test user"
      And a real server
      And a public room in this server
    When the user goes to the invite room with mobile page
    Then the action in the form should point to the mobile join

  @mechanize
  Scenario: Accessing from a mobile device the user should be redirected to the url
    Given a user named "test user"
      And a real server
      And a public room in this server
    When the user goes to the invite room with mobile page
      And enters his name and the moderator key
      And clicks in the button to join the conference from a mobile device
    Then he should be redirected to the conference using the "bigbluebutton://" protocol

  Scenario: The invite view shows a link to join from a desktop when joining from a mobile
    Given a user named "test user"
      And a real server
      And a public room in this server
    When the user goes to the invite room with mobile page
    Then he should see a link to join the conference from a desktop
