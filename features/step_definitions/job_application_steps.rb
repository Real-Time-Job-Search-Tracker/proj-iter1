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
  stub_request(:get, "https://example.com/failing-save")
    .to_return(
      status: 200,
      body: <<~HTML,
        <html>
          <head><title>Failing Save</title></head>
          <body>Dummy job page</body>
        </html>
      HTML
      headers: { "Content-Type" => "text/html" }
    )

  allow_any_instance_of(JobApplication).to receive(:save).and_return(false)

  allow_any_instance_of(JobApplication)
    .to receive_message_chain(:errors, :full_messages)
    .and_return([ "Please enter a valid URL" ])
end

When('I submit the new job application form') do
  visit new_application_path
  fill_in 'application_url', with: 'https://example.com/failing-save'
  click_button 'Add Application'
end

Then('I should see an alert containing {string}') do |msg|
  expect(page).to have_css('.alert', text: msg)
end
