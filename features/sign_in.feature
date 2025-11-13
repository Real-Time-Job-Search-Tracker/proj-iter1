Feature: Sign in
  As a user
  I want to sign in
  So that I can add and track my applications

  Background:
    Given a user exists with email "alice@example.com" and password "password"

  Scenario: Successful sign in
    When I visit the sign in page
    And I sign in as "alice@example.com" with password "password"
    Then I should see "Overview"

  Scenario: Sign in fails with wrong password
    When I visit the sign in page
    And I sign in as "alice@example.com" with password "wrong-password"
    Then I should see "Invalid email or password"
    And I should be on the sign in page
