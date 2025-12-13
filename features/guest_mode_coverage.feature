Feature: Guest Mode Controller Coverage
  As a guest user
  I want to use the API endpoints
  So that I can verify the logic for non-authenticated sessions

  Scenario: Guest adds, updates, and deletes an application (Full Lifecycle)
    Given I am not signed in
    
    # 1. Test Index (Guest)
    When I request "/applications"
    Then the response status should be 200
    And the JSON response should be an array
    
    # 2. Test Create (Guest)
    When I send a POST request to "/applications" with JSON:
      """
      {
        "url": "https://jobs.lever.co/example/123",
        "company": "GuestCompany",
        "title": "GuestTitle",
        "status": "Applied"
      }
      """
    Then the response status should be 201
    And the JSON response should include "GuestCompany"
    And I save the "id" from the response
    
    # 3. Test Stats (Guest) - Ensure the added data is reflected in stats
    When I request "/applications/stats"
    Then the response status should be 200
    And the JSON response should include "nodes"
    
    # 4. Test Update (Guest)
    When I send a PATCH request to the saved application ID with JSON:
      """
      {
        "status": "Interview"
      }
      """
    Then the response status should be 200
    And the JSON response should include "Interview"
    
    # 5. Test Destroy (Guest)
    When I send a DELETE request to the saved application ID
    Then the response status should be 204
    
    # 6. Verify deletion
    When I request "/applications"
    Then the JSON response should not include "GuestCompany"