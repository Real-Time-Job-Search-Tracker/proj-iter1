When('I visit the dashboard page') do
  visit dashboard_path
end

When('I request the dashboard stats JSON') do
  Capybara.using_driver(:rack_test) do
    visit dashboard_stats_path(format: :json) 
  end
end

Then('the JSON should include a node {string}') do |label|
  data = JSON.parse(last_response.body)
  nodes = data["nodes"]
  expect(nodes).to include(label)
end