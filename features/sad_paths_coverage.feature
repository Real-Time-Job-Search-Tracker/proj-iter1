Feature: Sad Paths and Error Handling
  
  # Changed: Test on Dashboard instead of the non-existent /applications/new page
  Scenario: Create application with invalid URL (HTML format)
    Given I am signed in as "alice@example.com" with password "password"
    When I visit the dashboard page
    # Using the field ID or name attribute logic from your dashboard form
    And I fill in "Final apply URL" with "invalid-url-text"
    And I click the "Add Application" button
    Then I should see "Please enter a valid URL"

  Scenario: Create application with invalid URL (JSON format)
    Given I am not signed in
    When I send a POST request to "/applications" with JSON:
      """
      {
        "url": "ftp://bad-scheme.com",
        "company": "BadCo"
      }
      """
    Then the response status should be 422
    And the JSON response should include "Please enter a valid URL"

  Scenario: Update non-existent application (Guest)
    Given I am not signed in
    # Use a random ID that definitely doesn't exist
    When I send a PATCH request to "/applications/99999999" with JSON:
      """
      { "status": "Offer" }
      """
    Then the response status should be 404

  Scenario: Update non-existent application (User)
    Given I am signed in as "alice@example.com" with password "password"
    When I send a PATCH request to "/applications/99999999" with JSON:
      """
      { "status": "Offer" }
      """
    Then the response status should be 404