require 'cgi'
require 'json'

When('I inspect the URL {string}') do |url|
  Capybara.using_driver(:rack_test) do
    visit inspect_job_path(url: url, format: :json)
  end
end

Then('the JSON should include {string}') do |text|
  data = JSON.parse(last_response.body)
  expect(data.values.join(" ")).to include(text)
end

Then('the JSON should include an error') do
  data = JSON.parse(last_response.body)
  expect(data["error"]).not_to be_nil
end