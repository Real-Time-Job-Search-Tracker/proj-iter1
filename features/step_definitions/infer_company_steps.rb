require 'rspec/expectations'
require_relative '../../app/controllers/applications_controller'

World(RSpec::Matchers)

When('I infer the company from URL {string}') do |url|
  controller = ApplicationsController.new
  @inferred_company = controller.send(:infer_company_from_url, url)
end

Then('the inferred company should be {string}') do |expected|
  expect(@inferred_company).to eq(expected)
end
