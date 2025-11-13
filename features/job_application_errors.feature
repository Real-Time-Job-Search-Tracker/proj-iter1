Feature: Handle errors when saving job applications
  As a user
  I want to see meaningful error messages
  So that I know why saving an application failed

  Background:
    Given I am signed in as "alice@example.com" with password "password"

  Scenario: Saving a job application fails - HTML request
    Given the next job application will fail to save
    When I submit the new job application form
    Then I should see an alert containing "Please enter a valid URL"
  
  Scenario: Saving a job application fails at the model layer (HTML)
    Given the next job application will fail to save
    When I submit the new job application form
    Then I should see an alert containing "Please enter a valid URL"
