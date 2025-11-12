Feature: Collect interview rounds from job histories
  As a developer
  I want to extract all stage labels that begin with "Round"
  So that I can track interview rounds from a user's job history

  Scenario: Histories include multiple rounds
    Given the following job histories:
      | status         |
      | Round 1 Phone  |
      | Applied        |
      | Round 2 Onsite |
      | Offer          |
    When I collect rounds from histories
    Then the result should be:
      | Round 1 |
      | Round 2 |

  Scenario: Histories include no rounds
    Given the following job histories:
      | status   |
      | Applied  |
      | Rejected |
    When I collect rounds from histories
    Then the result should be an empty list

  Scenario: Histories include nested arrays of rounds
    Given the following nested job histories:
      | status         |
      | Round 1 Tech   |
      | Round 2 Final  |
      | Offer          |
    When I collect rounds from histories
    Then the result should be:
      | Round 1 |
      | Round 2 |
