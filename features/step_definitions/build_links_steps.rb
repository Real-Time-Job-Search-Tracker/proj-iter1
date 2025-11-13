require 'rspec/expectations'
require_relative '../../app/controllers/applications_controller'

World(RSpec::Matchers)

Given('the following nodes:') do |table|
  @nodes = table.raw.flatten
end

Given('the following single-step paths:') do |table|
  @paths = table.hashes.map do |row|
    [row.fetch('from'), row.fetch('to')]
  end
end

Given('the following multi-step paths:') do |table|
  raw_paths = table.raw
  # Skip header if present
  data_rows = if raw_paths.first.first == 'path'
                raw_paths[1..] || []
              else
                raw_paths
              end

  @paths = data_rows.map do |row|
    row.first.split(/\s*,\s*/)
  end
end

When('I build links from paths') do
  controller = ApplicationsController.new
  @links = controller.send(:build_links_from_paths, @paths, @nodes)
end

Then('the links should be:') do |table|
  expected = table.hashes.map do |row|
    {
      source: @nodes.index(row.fetch('source')),
      target: @nodes.index(row.fetch('target')),
      value:  row.fetch('value').to_i,
      cls:    row.fetch('cls')
    }
  end

  sort_key = ->(h) { [h[:source], h[:target], h[:cls]] }

  expect(@links.sort_by(&sort_key)).to eq(expected.sort_by(&sort_key))
end

Then('there should be no links') do
  expect(@links).to eq([])
end
