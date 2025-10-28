@javascript
Feature: Sankey JSON
  As a user
  I want the sankey endpoint to reflect my pipeline
  So that I can visualize flow between stages

  Background:
    Given I am signed in as "alice@example.com" with password "password"
    And an application exists for "ACME Corp" in stage "Applied"

  Scenario: Returns non-empty sankey data
    When I request the sankey JSON
    Then the response should be JSON
    And the JSON should include a sankey node for "Applied"
    And the JSON should include at least 1 link