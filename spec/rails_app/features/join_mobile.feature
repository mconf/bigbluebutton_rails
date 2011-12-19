Feature: Join a webconference using a mobile device
  In order to participate in webconference using a mobile device
  One needs to access the page with the mobile link and QR code

  Scenario: Accessing the mobile join page
    Given a user named "test user"
      And a real server
      And a public room in this server
    When the user goes to the mobile join page
    Then he should see the QR code and a link to join using a mobile device
