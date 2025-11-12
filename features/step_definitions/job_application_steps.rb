require 'rspec/mocks'
World(RSpec::Mocks::ExampleMethods)

Before do
  RSpec::Mocks.setup
end

After do
  RSpec::Mocks.verify
  RSpec::Mocks.teardown
end

Given('the next job application will fail to save') do
  allow_any_instance_of(JobApplication).to receive(:save).and_return(false)
  allow_any_instance_of(JobApplication).to receive_message_chain(:errors, :full_messages)
    .and_return(["Please enter a valid URL"])
end

When('I submit the new job application form') do
  visit new_application_path
  # fill_in 'Title', with: ''
  fill_in 'application_url', with: ''
  click_button 'Add Application'
end

# When('I submit the new job application via JSON') do
  # page.driver.post new_application_path, params: { job_application: { title: '' } }, headers: { 'ACCEPT' => 'application/json' }
  # page.driver.post( applications_path, params: { job_application: { url: '' } }, headers: { 'ACCEPT' => 'application/json' } )
  # headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }
  #payload = { job_application: { url: '' } }.to_json
  #page.driver.post(applications_path, payload, headers)
  #page.driver.status_code
# end

Then('I should see an alert containing {string}') do |msg|
  expect(page).to have_css('.alert', text: msg)
end

#Then('the JSON response should contain an error {string}') do |msg|
  #puts "Response body: #{page.body}"
  #data = JSON.parse(page.body)
  #expect(data['error']).to eq(msg)
#end

#Then('the response status should be {int}') do |status|
  #expect(page.status_code).to eq(status)
#end
