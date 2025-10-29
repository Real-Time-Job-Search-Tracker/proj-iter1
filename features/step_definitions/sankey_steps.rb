Given('an application exists for {string} in stage {string}') do |company, stage_name|
  # TO-DO
  user = @current_user || User.first || FactoryBot.create(:user)
  @application = FactoryBot.create(
    :application,
    company: company,
    stage: stage_name,
    user: user
  )
end

When('I request the sankey JSON') do
  # TO-DO
  visit sankey_path(format: :json)
  @json_response = JSON.parse(page.body)
end

Then('the response should be JSON') do
  # TO-DO
  expect(@json_response).to be_a(Hash)
  expect(@json_response).to have_key('nodes')
  expect(@json_response).to have_key('links')
end

Then('the JSON should include a sankey node for {string}') do |stage_name|
  # TO-DO
  node_names = @json_response['nodes'].map { |n| n['name'] }
  expect(node_names).to include(stage_name)
end

Then('the JSON should include at least 1 link') do
  # TO-DO
  expect(@json_response['links'].length).to be >= 1
end