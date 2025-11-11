require "json"

Then("the response should be JSON") do
  parsed = JSON.parse(page.body)
  expect(parsed).to be_a(Hash).or be_a(Array)
end
