Feature: Monitor the active in the webconference servers
  To check the current status of a server
  One needs a real-time activity monitor

  @wip @need-bot
  Scenario: View the list of meetings running in a server
    Given an anonymous user
      And a real server
      And 2 meetings running in this server
    When he goes to the server activity monitor page
    Then he should see the 2 meetings that are running

  @wip @need-bot
  Scenario: View the list of meetings running in a server with no meetings running
    Given an anonymous user
      And a real server with no meetings running
    When he goes to the server activity monitor page
    Then he shouldn't see any meeting in the list

  @wip @need-bot
  Scenario: View the list of meetings in progress and meetings recently finished
    Given an anonymous user
      And a real server
      And 2 meetings running in this server
      And 2 meetings recently ended in this server
    When he goes to the server activity monitor page
    Then he should see the 2 meetings that are running
      And he should see the 2 recently ended meetings

  @wip @need-bot
  Scenario: View externally created meetings (in rooms that are not in the database)
    Given an anonymous user
      And a real server
      And an external room in this server
    When he goes to the server activity monitor page
    Then he should see the external room in the list

  @wip @need-bot
  Scenario: Contains a link to partially refresh the meeting list
    Given an anonymous user
      And a real server
      And 2 meetings running in this server
    When he goes to the server activity monitor page
      And the first meeting is ended
      And he clicks in the link to update the meeting list
    Then he should see 1 meeting running
      And he should see 1 meeting not running

  @wip @need-bot
  Scenario: Partially refresh the meeting list periodically
    Given an anonymous user
      And a real server
      And 2 meetings running in this server
    When he goes to the server activity monitor page
      And the first meeting is ended
    Then after 30 seconds he should see 1 meeting running
      And he should see 1 meeting not running
