require "json"
require "securerandom"

def parsed_sankey_json
  JSON.parse(page.text)
end

def sankey_nodes(data)
  data["nodes"] || data.dig("data", "nodes") || []
end

def sankey_links_as_objects(data)
  links = data["links"] || data.dig("data", "links")

  # Case 1: already an array of objects
  return links if links.is_a?(Array)

  # Case 2: columnar hash of arrays (Plotly style)
  if links.is_a?(Hash)
    sources = links["source"] || links[:source] || []
    targets = links["target"] || links[:target] || []
    values  = links["value"]  || links[:value]  || []
    clss    = links["cls"]    || links[:cls]    || []

    n = [ sources.length, targets.length, values.length, clss.length ].max

    return (0...n).map do |i|
      {
        "source" => sources[i],
        "target" => targets[i],
        "value"  => values[i],
        "cls"    => clss[i]
      }
    end
  end

  raise RSpec::Expectations::ExpectationNotMetError,
        "Expected 'links' to be an Array or a Hash-of-arrays, got: #{links.inspect}"
end


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
  page.driver.header 'Accept', 'application/json'
  visit sankey_api_path
end

Then("the JSON should include a sankey node for {string}") do |label|
  data  = parsed_sankey_json
  nodes = sankey_nodes(data)

  expect(nodes).to be_an(Array), "Expected 'nodes' to be an Array, got: #{nodes.inspect}"

  has_label =
    nodes.include?(label) ||
    nodes.any? { |n| n.is_a?(Hash) && [ n["id"], n["name"], n["label"], n["title"] ].compact.include?(label) }

  expect(has_label).to be(true), "Expected a node labeled #{label.inspect} in nodes=#{nodes.inspect}"
end

Then("the JSON should include at least 1 link") do
  data  = parsed_sankey_json
  links = sankey_links_as_objects(data)

  expect(links).to be_an(Array), "Expected links to normalize to an Array, got: #{links.inspect}"

  total = links.map { |l| (l["value"] || l[:value]).to_i }.sum
  expect(total).to be >= 1, "Expected total link value >= 1, got: #{total} (links=#{links.inspect})"
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
  data  = parsed_sankey_json
  links = sankey_links_as_objects(data)

  classes = links.map { |l| l["cls"] || l[:cls] }.compact
  expect(classes).to include(cls),
    "Expected a link with cls=#{cls.inspect} in classes=#{classes.inspect}"
end
