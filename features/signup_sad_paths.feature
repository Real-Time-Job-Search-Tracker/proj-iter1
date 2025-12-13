Feature: Signup and Jobs Edge Cases
  
  # Covers UsersController#create (Failure branch)
  Scenario: Signup fails with password mismatch
    Given I am not signed in
    # Sending raw params simulates a form submission failure
    When I send a HTML POST request to "/sign_up" with params:
      | user[username] | bob |
      | user[email]    | bob@example.com |
      | user[password] | password123 |
      | user[password_confirmation] | mismatch |
    # The controller renders :new with status unprocessable_entity (no redirect)
    Then the response status should be 422
    And I should see "Password confirmation doesn't match"

  # Covers JobsController#preview (Missing URL)
  Scenario: Jobs preview API returns error for missing URL
    Given I am not signed in
    # This uses the API helper steps we defined earlier
    When I request "/jobs/preview?url="
    Then the response status should be 400
    And the JSON response should include "Missing URL"

  # Covers JobsController#preview (Success path - HTTParty)
  # We use a real URL to trigger the "begin" block
  Scenario: Jobs preview API fetches data for valid URL
    Given I am not signed in
    When I request "/jobs/preview?url=https://example.com"
    Then the response status should be 200
    And the JSON response should include "url"
    And the JSON response should include "title"