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
  if page.has_button?("Add Application", wait: 0.5)
    click_button "Add Application"
  elsif page.has_button?("Add", wait: 0.5)
    click_button "Add"
  else
    find("input[type=submit], button[type=submit]", match: :first).click
  end
end

Then('I should see {string}') do |content|
  expect(page).to have_content(content)
end

Then("I should see {string} within the applications list") do |company|
  visit applications_path unless page.has_css?("#applications, #applications_list, .applications, .apps", wait: 0.5)

  containers = [ "#applications", "#applications_list", ".applications", ".apps" ]
  if (container = containers.find { |sel| page.has_css?(sel) })
    within(container) { expect(page).to have_text(company) }
  else
    # fall back to whole page if the page itself *is* the list
    expect(page).to have_text(company)
  end
end

Then('I should see the stage {string} for {string}') do |stage, company|
  #
  app = JobApplication.find_by!(company: company)
  expect(app.status).to eq(stage)
end

Then('I should not see {string}') do |content|
  #
  expect(page).not_to have_content(content)
end
