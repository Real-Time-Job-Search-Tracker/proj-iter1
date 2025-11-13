@javascript
Feature: Add an application from a final-apply URL
  As a user
  I want to paste the employer's final apply URL
  So that the app creates/updates a tracked application for me

  Background:
    Given I am signed in as "alice@example.com" with password "password"

  Scenario: Happy path - valid final apply URL
    Given the parser will return job details for "https://jobs.workday.com/acme/job123"
    When I paste "https://jobs.workday.com/acme/job123" into the Add Application form
    And I submit the form
    Then I should see "Application added"
    And I should see "ACME Corp" within the applications list
    And I should see the stage "Applied" for "ACME Corp"

  Scenario: Sad path - invalid URL
    When I paste "not-a-url" into the Add Application form
    And I submit the form
    Then I should see "Please enter a valid URL"
    And I should not see "ACME Corp"
  Scenario: Enrich company/title from parsed page
    Given the parser will return job details for "https://jobs.example.com/acme/123"
    When I paste "https://jobs.example.com/acme/123" into the Add Application form
    And I submit the form
    Then I should see "Application added"
    And I should see "ACME Corp" within the applications list

  Scenario: Infer company from Greenhouse URL
    When I paste "https://boards.greenhouse.io/mega-corp/jobs/42" into the Add Application form
    And I submit the form
    Then I should see "Application added"
    And I should see "Mega corp" within the applications list

  Scenario: Infer company from Lever URL
    When I paste "https://jobs.lever.co/startup-xyz/abcdef" into the Add Application form
    And I submit the form
    Then I should see "Application added"
    And I should see "Startup xyz" within the applications list
