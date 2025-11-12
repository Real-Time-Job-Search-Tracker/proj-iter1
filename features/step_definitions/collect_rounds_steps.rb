require 'set'
require_relative '../../app/helpers/application_helper'

module StageLabelStub
  def stage_label(status)
    match = status.to_s.match(/Round\s*\d+/)
    match ? match[0] : status.to_s
  end
end

World(ApplicationHelper)
World(StageLabelStub)

Given('the following job histories:') do |table|
  @histories = table.hashes
end

Given('the following nested job histories:') do |table|
  @histories = [table.hashes]
end

When('I collect rounds from histories') do
  @result = collect_rounds_from_histories(@histories)
end

Then('the result should be:') do |table|
  expected = table.raw.flatten
  expect(@result).to eq(expected)
end

Then('the result should be an empty list') do
  expect(@result).to eq([])
end
