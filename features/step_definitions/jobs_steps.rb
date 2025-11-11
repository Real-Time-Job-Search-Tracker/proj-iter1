require "cgi"
require "json"

When('I inspect the URL {string}') do |url|
  visit "/jobs/inspect.json?url=#{CGI.escape(url)}"
end

Then('the JSON should include {string}') do |text|
  data = JSON.parse(page.body)
  # search in a simple, forgiving way
  flat = data.values.map { |v| v.is_a?(String) ? v : v.to_s }.join(" ")
  expect(flat).to include(text)
end

Then('the JSON should include an error') do
  data = JSON.parse(page.body)
  expect(data["error"]).to be_present
end
