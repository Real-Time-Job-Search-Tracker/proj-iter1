Feature: Profile Controller Logic Coverage
  As a user
  I want to verify profile security logic
  So that I know my account updates are validated

  Background:
    Given I am signed in as "alice@example.com" with password "password"

  # Covers ProfilesController#update (Success)
  Scenario: Update profile with valid data
    When I send a HTML PATCH request to "/profile" with params:
      | user[username] | AliceUpdated |
      | user[daily_goal] | 5 |
    Then I follow the redirect
    And I should see "Profile updated"

  # Covers ProfilesController#update_password (Failure: Current password incorrect)
  Scenario: Update password fails with wrong current password
    When I send a HTML PATCH request to "/profile/password" with params:
      | current_password | wrong_pass |
      | new_password     | new123     |
      | new_password_confirmation | new123 |
    Then I follow the redirect
    And I should see a flash message "Current password is incorrect"

  # Covers ProfilesController#update_password (Failure: Blank new password)
  Scenario: Update password fails with blank new password
    When I send a HTML PATCH request to "/profile/password" with params:
      | current_password | password |
      | new_password     |          |
    Then I follow the redirect
    And I should see a flash message "New password cannot be blank"

  # Covers ProfilesController#update_password (Failure: Mismatch)
  Scenario: Update password fails with confirmation mismatch
    When I send a HTML PATCH request to "/profile/password" with params:
      | current_password | password |
      | new_password     | new123   |
      | new_password_confirmation | mismatch |
    Then I follow the redirect
    And I should see a flash message "Password confirmation does not match"

  # Covers ProfilesController#update_password (Success)
  Scenario: Update password successfully
    When I send a HTML PATCH request to "/profile/password" with params:
      | current_password | password |
      | new_password     | newpass123 |
      | new_password_confirmation | newpass123 |
    Then I follow the redirect
    And I should see "Password updated"