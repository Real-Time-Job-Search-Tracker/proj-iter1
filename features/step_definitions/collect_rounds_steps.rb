require 'set'
require_relative '../../app/helpers/application_helper'
require Rails.root.join('app/controllers/applications_controller')

Before do
  @apps_ctrl = ApplicationsController.new
end

Given('the following job histories:') do |table|
  @histories = [table.hashes]
end

Given('the following nested job histories:') do |table|
  @histories = [table.hashes]
end

When('I collect rounds from histories') do
  # If you want to use the real stage_label for coverage:
  # nothing to stub
  @result = @apps_ctrl.send(:collect_rounds_from_histories, @histories)
end

Then('the result should be:') do |table|
  expect(@result).to eq(table.raw.flatten)
end

Then('the result should be an empty list') do
  expect(@result).to eq([])
end
