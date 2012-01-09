Feature: List and show webconference rooms
  To view information of a webconference room
  One needs to see the room in a list of rooms
    and see all the information it has stored

  Scenario: View the list of rooms
    Given an anonymous user
      And a real server
      And 3 rooms in this server
    When he goes to the rooms index page
    Then he should see all available rooms in the list

  Scenario: View all information of a room
    Given an anonymous user
      And a real server
      And a room in this server
    When he goes to the show room page
    Then he should see all the information available for this room

  Scenario: View the list of rooms for a single server
    Given an anonymous user
      And a real server
      And 3 rooms in this server
      And 2 rooms in any other server
    When he goes to the server rooms page
    Then he should see only the rooms from this server
