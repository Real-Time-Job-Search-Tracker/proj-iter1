@javascript
Feature: Update job application status
  As a user
  I want to update the status of a job
  So that the dashboard, job list, and Sankey diagram all reflect the change

  Background:
    Given the following job applications exist:
      | company | url                       | title            | status   |
      | Tesla   | http://tesla.com/job1     | Software Eng     | Applied  |
      | Airbnb  | http://airbnb.com/job42   | Data Analyst     | Screening |

    And I am on the jobs index page

  Scenario: Change status and verify filter works
    When I change the status of "Airbnb" to "Accepted"
    And I select the filter "Accepted"
    Then only "Airbnb" should be visible in the jobs table

  Scenario: Change status and verify persistence after refresh
    When I change the status of "Tesla" to "Offer"
    And I refresh the page
    Then I should see "Offer" as the status for "Tesla" in the table