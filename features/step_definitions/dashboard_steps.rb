require "json"

When("I visit the dashboard page") do
  visit dashboard_path
end

When("I request the applications stats JSON") do
  page.driver.header "Accept", "application/json"
  visit "/applications/stats"
end

Then("the JSON should include a node {string}") do |label|
  data  = JSON.parse(page.body)
  nodes = data["nodes"] || data.dig("data", "nodes") || []
  expect(nodes).to include(label)
end
