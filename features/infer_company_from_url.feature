Feature: Infer company name from URL
  As a stats helper
  I want to infer the company name from a job URL
  So that applications have a reasonable default company

  Scenario: Greenhouse boards URL with company slug
    When I infer the company from URL "https://boards.greenhouse.io/acme-corp/jobs/123"
    Then the inferred company should be "Acme corp"

  Scenario: Lever URL with company slug
    When I infer the company from URL "https://jobs.lever.co/acme-corp/12345"
    Then the inferred company should be "Acme corp"

  Scenario: Generic domain
    When I infer the company from URL "https://example.com/jobs/123"
    Then the inferred company should be "Example"

  Scenario: Multi-level domain (workday)
    When I infer the company from URL "https://jobs.workday.com/acme/job123"
    Then the inferred company should be "Workday"

  Scenario: Blank URL
    When I infer the company from URL ""
    Then the inferred company should be "Unknown"

  Scenario: Invalid URL that cannot be parsed
    When I infer the company from URL ":::not-a-valid-url"
    Then the inferred company should be "Unknown"
