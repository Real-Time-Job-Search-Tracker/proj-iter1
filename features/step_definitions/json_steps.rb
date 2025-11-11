require "json"

Then('the response should be JSON') do
  expect { JSON.parse(page.body) }.not_to raise_error
end
