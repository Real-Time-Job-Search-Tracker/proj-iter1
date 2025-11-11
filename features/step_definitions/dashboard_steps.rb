When('I visit the dashboard page') do
  visit dashboard_path
end

When('I request the dashboard stats JSON') do
  visit stats_dashboard_path
end

Then('the JSON should include a node {string}') do |label|
  data = JSON.parse(page.body)
  nodes = data["nodes"]
  expect(nodes).to include(label)
end
