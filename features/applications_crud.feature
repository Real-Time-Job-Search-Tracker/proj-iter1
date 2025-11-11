@javascript
Feature: Update and delete applications
  As a user
  I want to update or delete my applications
  So that my pipeline stays accurate

  Background:
    Given I am signed in as "alice@example.com" with password "password"
    And an application exists for "ACME Corp" in stage "Applied"

  # Scenario: Update application status
    # When I update the application for "ACME Corp" to status "Round1"
    # Then the application for "ACME Corp" should have status "Round1"

  Scenario: Delete an application
    When I delete the application for "ACME Corp"
    Then I should not see "ACME Corp" in the applications list

  Scenario: Visit new application form
    When I visit the new application page
    Then I should see "Add Application"
