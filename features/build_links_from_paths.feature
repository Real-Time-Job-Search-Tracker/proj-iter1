Feature: Build Sankey links from stage paths
  As a stats builder
  I want to turn status paths into Sankey links
  So that transitions are counted and classified

  Scenario: Classify all transition types
    Given the following nodes:
      | Applications |
      | Round1       |
      | Round2       |
      | Offer        |
      | Accepted     |
      | Declined     |
      | Ghosted      |
      | Other        |
    And the following single-step paths:
      | from          | to        |
      | Applications  | Round1    |
      | Applications  | Ghosted   |
      | Round1        | Round2    |
      | Round2        | Offer     |
      | Round1        | Ghosted   |
      | Offer         | Accepted  |
      | Offer         | Declined  |
      | Offer         | Ghosted   |
      | Applications  | Other     |
    When I build links from paths
    Then the links should be:
      | source        | target   | value | cls               |
      | Applications  | Round1   | 1     | apps_to_round     |
      | Applications  | Ghosted  | 1     | apps_to_ghosted   |
      | Round1        | Round2   | 1     | round_to_round    |
      | Round2        | Offer    | 1     | round_to_offer    |
      | Round1        | Ghosted  | 1     | round_to_ghosted  |
      | Offer         | Accepted | 1     | offer_to_accepted |
      | Offer         | Declined | 1     | offer_to_declined |
      | Offer         | Ghosted  | 1     | offer_to_ghosted  |
      | Applications  | Other    | 1     | other             |

  Scenario: Count multiple occurrences of the same edge
    Given the following nodes:
      | Applications |
      | Round1       |
      | Offer        |
    And the following multi-step paths:
      | path                        |
      | Applications,Round1,Offer   |
      | Applications,Round1,Offer   |
    When I build links from paths
    Then the links should be:
      | source        | target | value | cls           |
      | Applications  | Round1 | 2     | apps_to_round |
      | Round1        | Offer  | 2     | round_to_offer |

  Scenario: Ignore transitions involving unknown nodes
    Given the following nodes:
      | Applications |
      | Round1       |
    And the following single-step paths:
      | from          | to          |
      | Applications  | MissingNode |
    When I build links from paths
    Then there should be no links
