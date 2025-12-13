require "json"

Given("the next job application will fail to save") do
  @job_app_url     = "not-a-url"
  @job_app_status  = "Applied"
  @job_app_company = ""
  @job_app_title   = ""
end

When("I submit the new job application form") do
  visit dashboard_path

  fill_in "application_url", with: (@job_app_url || "not-a-url")

  if @job_app_status
    select @job_app_status, from: "application_status"
  end

  fill_in "application_company", with: @job_app_company.to_s if page.has_field?("application_company", wait: 1)
  fill_in "application_title",   with: @job_app_title.to_s   if page.has_field?("application_title", wait: 1)

  click_button "Add Application"
end

Then("I should see an alert containing {string}") do |msg|
  expect(page).to have_text(msg, wait: 5)

  expect(page).to have_css("#toast-container, .toast, .alert, .flash", text: msg, wait: 5, visible: :all)
end
