Feature: Manage job applications
  As a user
  I want to update or delete job applications
  So that my application list stays current

  Background:
    Given there is a job application for "ACME Corp" with title "Engineer" and status "Applied"

  Scenario: Update a job application’s status
    When I update the status of "ACME Corp" to "Interviewing"
    Then the status of "ACME Corp" should be "Interviewing"

  Scenario: Delete a job application
    When I delete the job application for "ACME Corp"
    Then the job application for "ACME Corp" should not exist