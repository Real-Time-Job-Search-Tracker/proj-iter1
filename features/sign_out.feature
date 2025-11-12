Feature: Sign out
  As a signed-in user
  I want to sign out
  So that no one else can use my account

  Background:
    Given I am signed in as "alice@example.com" with password "password"

  Scenario: Successful sign out
    When I sign out
    Then I should see "Signed out"
    And I should be on the sign in page
