require "json"

Given("an application exists for {string} in stage {string}") do |company, stage|
  JobApplication.create!(
    url:     "https://example.com/#{company.parameterize}",
    company: company,
    title:   "Engineer",
    status:  stage,
    history: [ { "status" => stage, "ts" => Time.now.utc.iso8601 } ]
  )
end

# features/step_definitions/sankey_steps.rb
When("I request the sankey JSON") do
  # page.driver.browser.execute_cdp("Network.setExtraHTTPHeaders", headers: { "ACCEPT" => "application/json" })
  visit "/applications/stats.json"
end

Then("the response should be JSON") do
  # Don’t rely on response headers (not supported by Selenium driver)
  expect { JSON.parse(page.text) }.not_to raise_error, "Expected JSON, got HTML (starts with: #{page.text[0, 60].inspect})"
end

Then("the JSON should include a sankey node for {string}") do |label|
  data  = JSON.parse(page.text)

  nodes = data["nodes"] || data.dig("data", "nodes")
  expect(nodes).to be_an(Array), "Expected 'nodes' to be an Array, got: #{nodes.inspect}"

  # Accept either an array of strings, or an array of objects with a name-ish field
  has_label =
    nodes.include?(label) ||
    nodes.any? { |n| n.is_a?(Hash) && [ n["id"], n["name"], n["label"], n["title"] ].compact.include?(label) }

  expect(has_label).to be(true), "Expected a node labeled #{label.inspect} in nodes=#{nodes.inspect}"
end

Then("the JSON should include at least 1 link") do
  data  = JSON.parse(page.text)
  links = data["links"] || data.dig("data", "links")
  expect(links).to be_an(Array), "Expected 'links' to be an Array of objects, got: #{links.inspect}"
  values = links.map { |l| l.is_a?(Hash) ? l["value"] || l[:value] : nil }.compact
  expect(values.map(&:to_i).sum).to be >= 1
end
