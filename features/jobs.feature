@javascript
Feature: Job URL inspection
  As a user
  I want to inspect job URLs
  So that I can pre-fill company/title from the page

  Background:
    Given I am signed in as "alice@example.com" with password "password"

  Scenario: Inspect a valid job URL
    Given the parser will return job details for "https://jobs.workday.com/acme/job123"
    When I inspect the URL "https://jobs.workday.com/acme/job123"
    Then the response should be JSON
    And the JSON should include "ACME Corp"
    And the JSON should include "Job Title"

  Scenario: Inspect an invalid URL
    When I inspect the URL "not-a-url"
    Then the response should be JSON
    And the JSON should include an error