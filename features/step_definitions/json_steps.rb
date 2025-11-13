require "json"

Then("the response should be JSON") do
  Capybara.current_driver = :rack_test
  expect {
    JSON.parse(page.body)
  }.not_to raise_error
end