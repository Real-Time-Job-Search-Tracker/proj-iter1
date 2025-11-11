@javascript
Feature: Dashboard overview
  As a signed-in user
  I want to see my dashboard and job stats

  Background:
    Given I am signed in as "alice@example.com" with password "password"

  Scenario: Visiting the dashboard
    When I visit the dashboard page
    Then I should see "Overview"

  Scenario: Dashboard stats JSON
    Given an application exists for "ACME Corp" in stage "Applied"
    When I request the dashboard stats JSON
    Then the response should be JSON
    And the JSON should include a node "Applied"
