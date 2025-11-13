require "securerandom"
require_relative "../../app/services/sankey/builder"

Given("a sankey test application with history:") do |table|
  rows = table.hashes

  now = Time.now.utc
  history = rows.each_with_index.map do |row, i|
    {
      "status" => row["status"],
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

Given("the current status of that sankey application is {string}") do |status|
  raise "No @sankey_app defined" unless @sankey_app
  @sankey_app.update!(status: status)
end

Given("a sankey app with history:") do |table|
  rows = table.hashes

  now = Time.now.utc
  history = rows.each_with_index.map do |row, i|
    {
      "status" => row["status"],
      "ts"     => (now - (rows.size - i).hours).iso8601
    }
  end

  @app = JobApplication.create!(
    url:     "https://example.com/#{SecureRandom.hex(4)}",
    company: "TestCo",
    title:   "Engineer",
    status:  history.last["status"],
    history: history
  )
end

Given("the current status of that app is {string}") do |status|
  raise "@app is nil" unless @app
  @app.update!(status: status)
end

When("I build the sankey from all applications") do
  @sankey_data = Sankey::Builder.call(JobApplication.all)
end

When("I build the sankey now") do
  @sankey = Sankey::Builder.call(JobApplication.all)
end

Then("the canonical path for that sankey application should end at {string}") do |final|
  raise "No @sankey_app defined" unless @sankey_app

  path = Sankey::Builder.canonical_path(@sankey_app.history, @sankey_app.status)
  expect(path.last).to eq(final),
    "Expected canonical path to end at #{final.inspect}, got #{path.inspect}"
end

Then("the sankey should include a link from {string} to {string} with class {string}") do |from, to, cls|
  data  = @sankey_data or raise "@sankey_data is nil – did you run 'When I build the sankey from all applications'?"

  nodes = data[:nodes] || data["nodes"]
  links = data[:links] || data["links"]

  if links.is_a?(Hash)
    sources = links[:source] || links["source"] || []
    targets = links[:target] || links["target"] || []
    classes = links[:cls]    || links["cls"]    || []
  else
    raise "Expected links to be a Hash, got #{links.inspect}"
  end

  i_from = nodes.index(from)
  i_to   = nodes.index(to)

  expect(i_from).not_to be_nil, "Could not find node #{from.inspect} in nodes=#{nodes.inspect}"
  expect(i_to).not_to be_nil,   "Could not find node #{to.inspect} in nodes=#{nodes.inspect}"

  found = sources.each_with_index.any? do |s, i|
    s == i_from && targets[i] == i_to && classes[i] == cls
  end

  expect(found).to be(true),
    "Expected a link #{from.inspect} -> #{to.inspect} with class #{cls.inspect}, " \
    "but links were: #{sources.zip(targets, classes).inspect}"
end

Then(
  "the sankey should include a transition {string} → {string} with class {string}"
) do |from, to, cls|
  data = @sankey
  raise "No sankey data" unless data

  nodes = data[:nodes]
  links = data[:links]

  from_i = nodes.index(from.capitalize)
  to_i   = nodes.index(to.capitalize)

  expect(from_i).not_to be_nil, "Node #{from} not found"
  expect(to_i).not_to be_nil,   "Node #{to} not found"

  sources = links[:source]
  targets = links[:target]
  classes = links[:cls]

  found = sources.each_with_index.any? do |src, i|
    src == from_i &&
      targets[i] == to_i &&
      classes[i] == cls
  end

  expect(found).to be(true),
    "Expected transition #{from} → #{to} class=#{cls}, but got: #{sources.zip(targets, classes).inspect}"
end
