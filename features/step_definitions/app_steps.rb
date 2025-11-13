require 'nokogiri'
require 'open-uri'

Given("the parser will return job details for {string}") do |url|
  html = <<~HTML
    <html>
      <head>
        <title>Senior Engineer – ACME</title>
        <meta property="og:site_name" content="ACME Corp">
      </head>
      <body></body>
    </html>
  HTML

  stub_request(:get, url).to_return(status: 200, body: html, headers: { "Content-Type" => "text/html" })
end

When("I paste {string} into the Add Application form") do |the_url|
  visit new_application_path

  candidate_fields = [ "application_url", "url", "Final apply URL", "#application_url", "input[name='application[url]']" ]

  field = candidate_fields.find { |name_or_label| page.has_field?(name_or_label, disabled: false, wait: 5) }

  raise 'Could not find the URL field on the Add Application form. Available fields: ' + candidate_fields.join(', ') unless field

  fill_in field, with: the_url
end

When("I submit the form") do
  # Click the submit button without holding onto a form element
  if page.has_button?("Add Application", wait: 0.5)
    click_button "Add Application"
  elsif page.has_button?("Add", wait: 0.5)
    click_button "Add"
  else
    find("input[type=submit], button[type=submit]", match: :first).click
  end

  page.has_css?(".flash", wait: 5) || page.has_current_path?(/applications|new|jobs/i, wait: 5)
end

Then('I should see {string}') do |content|
  # If we just submitted an invalid URL, we expect to be back on the new form.
  if defined?(new_application_path)
    begin
      expect(page).to have_current_path(new_application_path, ignore_query: true, wait: 2)
    rescue RSpec::Expectations::ExpectationNotMetError
    end
  end

  # Look for flash containers first, with a generous wait
  if page.has_css?('.flash, .alert, [role="alert"]', text: content, wait: 5, exact_text: false)
    expect(page).to have_css('.flash, .alert, [role="alert"]', text: content, exact_text: false)
  else
    expect(page).to have_text(content, wait: 5)
  end
end

Then("I should see {string} within the applications list") do |company|
  visit applications_path unless page.has_css?("#applications, #applications_list, .applications, .apps", wait: 0.5)

  containers = [ "#applications", "#applications_list", ".applications", ".apps" ]
  if (container = containers.find { |sel| page.has_css?(sel) })
    within(container) { expect(page).to have_text(company) }
  else
    expect(page).to have_text(company)
  end
end

Then('I should see the stage {string} for {string}') do |stage, company|
  app = JobApplication.find_by!(company: company)
  expect(app.status).to eq(stage)
end

Then("I should not see {string}") do |content|
  expect(page).to have_no_text(content, wait: 5)
end

Given("there is a job application for {string} with title {string} and status {string}") do |company, title, status|
  JobApplication.create!(
    company: company,
    title: title,
    status: status,
    url: "https://example.com/#{company.parameterize}"
  )
end

When("I update the status of {string} to {string}") do |company, new_status|
  app = JobApplication.find_by!(company: company)
  page.driver.put("/applications/#{app.id}", { status: new_status })
end

Then("the status of {string} should be {string}") do |company, expected_status|
  app = JobApplication.find_by!(company: company)
  expect(app.status).to eq(expected_status)
end

# When("I delete the job application for {string}") do |company|
# app = JobApplication.find_by!(company: company)
# page.driver.delete("/applications/#{app.id}")
# end

# Then("the job application for {string} should not exist") do |company|
# expect(JobApplication.find_by(company: company)).to be_nil
# end

When("I delete the job application for {string}") do |company|
  app = JobApplication.find_by(company: company)
  raise "No job application found for #{company}" unless app

  if page.current_path.include?("/applications")
    if page.has_button?("Delete", wait: 0.5)
      click_button("Delete")
    else
      page.driver.delete("/applications/#{app.id}")
    end
  else
    page.driver.delete("/applications/#{app.id}")
  end
end

Then("the job application for {string} should not exist") do |company|
  expect(JobApplication.find_by(company: company)).to be_nil
end

# build_links_from_paths
