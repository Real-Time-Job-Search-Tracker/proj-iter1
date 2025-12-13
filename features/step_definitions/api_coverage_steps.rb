require 'json'
require 'webmock/cucumber' # Ensure WebMock is available

# --- API Helpers ---

Given("I am not signed in") do
  page.driver.submit :delete, "/sign_out", {}
end

def send_api_request(method, path, body = nil)
  # Mock external request if we are calling the preview endpoint with example.com
  if path.include?("example.com")
    stub_request(:get, "https://example.com/").
      with(headers: {'User-Agent'=>'Mozilla/5.0'}).
      to_return(status: 200, body: "<html><title>Example Domain</title></html>", headers: {})
  end

  page.driver.header 'Accept', 'application/json'
  page.driver.header 'Content-Type', 'application/json'
  
  if body
    page.driver.send(method, path, body)
  else
    page.driver.send(method, path)
  end
  
  # Clean up headers
  page.driver.header 'Accept', nil
  page.driver.header 'Content-Type', nil
end

When("I request {string}") do |path|
  send_api_request(:get, path)
end

When("I send a POST request to {string} with JSON:") do |path, json_string|
  send_api_request(:post, path, json_string)
end

When("I send a PATCH request to {string} with JSON:") do |path, json_string|
  send_api_request(:put, path, json_string)
end

When("I send a PATCH request to the saved application ID with JSON:") do |json_string|
  raise "No ID saved!" unless @saved_id
  path = "/applications/#{@saved_id}"
  send_api_request(:put, path, json_string)
end

When("I send a DELETE request to the saved application ID") do
  raise "No ID saved!" unless @saved_id
  path = "/applications/#{@saved_id}"
  send_api_request(:delete, path)
end

# --- Assertions ---

Then("the response status should be {int}") do |status_code|
  expect(page.status_code).to eq(status_code)
end

Then("the JSON response should be an array") do
  data = JSON.parse(page.body)
  expect(data).to be_a(Array)
end

Then("the JSON response should include {string}") do |content|
  expect(page.body).to include(content)
end

Then("the JSON response should not include {string}") do |content|
  expect(page.body).not_to include(content)
end

Then("I save the {string} from the response") do |key|
  data = JSON.parse(page.body)
  if data.is_a?(Hash)
    @saved_id = data[key] || data[key.to_sym]
  else
    @saved_id = data.first[key]
  end
end

# --- Form Interaction Helpers ---

When("I fill in {string} with {string}") do |field_label, value|
  fill_in field_label, with: value
end

When("I click the {string} button") do |button_text|
  if page.has_button?(button_text)
    click_button button_text
  else
    find("input[value='#{button_text}']").click
  end
end