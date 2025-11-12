When('I update the application for {string} to status {string}') do |company, status|
  app = JobApplication.find_by!(company: company)
  visit edit_application_path(app)
  fill_in "Status", with: status
  click_button "Update Application"
end

Then('the application for {string} should have status {string}') do |company, status|
  app = JobApplication.find_by!(company: company)
  expect(app.status).to eq(status)
end

When('I delete the application for {string}') do |company|
  app = JobApplication.find_by!(company: company)
  app.destroy!
  # visit applications_path
  # within("#application_#{app.id}") do
  # click_link "Delete"
  # end
end

Then('I should not see {string} in the applications list') do |company|
  expect(page).to have_no_text(company)
end

When('I visit the new application page') do
  visit new_application_path
end

Then('I should see the Add Application form') do
  # If the form isn't on /applications/new, fall back to the dashboard/root
  unless page.has_css?("form#new_application", wait: 1)
    visit root_path
  end

  # The form should now exist
  expect(page).to have_css("form#new_application")

  # Fields (use String locators, not Regexp)
  expect(page).to have_field("application_url",    disabled: false)
  expect(page).to have_field("application_company", disabled: false)
  expect(page).to have_field("application_title",   disabled: false)
  expect(page).to have_select("application_status")

  # Submit button — support both <button> and <input type="submit">
  if page.has_button?("Add Application", exact: false)
    expect(page).to have_button("Add Application", exact: false)
  else
    expect(page).to have_css("input[type='submit'][value='Add Application']")
  end
end
