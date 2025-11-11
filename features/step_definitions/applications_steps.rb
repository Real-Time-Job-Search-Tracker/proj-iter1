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
