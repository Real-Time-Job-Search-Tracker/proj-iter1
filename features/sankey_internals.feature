Feature: Sankey builder internal transitions
  As a developer
  I want the Sankey::Builder to classify transitions correctly
  So that links and canonical paths are built as expected

  Background:
    Given a user exists with email "alice@example.com" and password "password"

  Scenario: Offer -> Accepted transition is classified as offer_to_accepted
    Given a sankey test application with history:
      | status  |
      | Applied |
      | Offer   |
    And the current status of that sankey application is "Accepted"
    When I build the sankey from all applications
    Then the canonical path for that sankey application should end at "Accepted"
    And the sankey should include a link from "Offer" to "Accepted" with class "offer_to_accepted"

    Scenario: Offer -> Declined maps to offer_to_declined
    Given a sankey app with history:
      | status  |
      | Applied |
      | Offer   |
    And the current status of that app is "Declined"
    When I build the sankey now
    Then the sankey should include a transition "Offer" → "Declined" with class "offer_to_declined"

  Scenario: Offer -> Ghosted maps to offer_to_ghosted
    Given a sankey app with history:
      | status  |
      | Applied |
      | Offer   |
    And the current status of that app is "Ghosted"
    When I build the sankey now
    Then the sankey should include a transition "Offer" → "Ghosted" with class "offer_to_ghosted"

  Scenario: Applied -> Declined maps to other
    Given a sankey app with history:
      | status   |
      | Applied  |
      | Declined |
    And the current status of that app is "Declined"
    When I build the sankey now
    Then the sankey should include a transition "Applied" → "Declined" with class "other"
