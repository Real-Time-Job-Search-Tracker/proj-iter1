require "json"
require "securerandom"

Given("an application exists for {string} in stage {string}") do |company, stage|
  JobApplication.create!(
    url:     "https://example.com/#{company.parameterize}",
    company: company,
    title:   "Engineer",
    status:  stage,
    history: [ { "status" => stage, "ts" => Time.now.utc.iso8601 } ]
  )
end


When("I request the sankey JSON") do
  Capybara.current_driver = :rack_test
  page.driver.header 'Accept', 'application/json'
  visit sankey_api_path
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

Given("an application with history:") do |table|
  rows = table.hashes  # [{ "status" => "Applied" }, { "status" => "Offer" }, ...]
  now  = Time.now.utc

  history = rows.each_with_index.map do |row, i|
    {
      "status" => row["status"],
      # give each step a deterministic-but-ordered timestamp
      "ts"     => (now - (rows.size - i).hours).iso8601
    }
  end

  last_status = history.last["status"]

  @sankey_app = JobApplication.create!(
    url:     "https://example.com/#{SecureRandom.hex(4)}",
    company: "SankeyCo",
    title:   "Engineer",
    status:  last_status,
    history: history
  )
end

Given("the current status of that application is {string}") do |status|
  raise "No @sankey_app defined" unless @sankey_app
  @sankey_app.update!(status: status)
end

Then("the JSON should include a link class {string}") do |cls|
  data  = JSON.parse(page.text)
  links = data["links"] || data.dig("data", "links")

  expect(links).to be_an(Array), "Expected 'links' to be an Array, got: #{links.inspect}"

  classes = links.map { |l| l["cls"] || l[:cls] }.compact
  expect(classes).to include(cls),
    "Expected a link with cls=#{cls.inspect} in classes=#{classes.inspect}"
end
