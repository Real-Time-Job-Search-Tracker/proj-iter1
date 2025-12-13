require "securerandom"

Given('there is a job application for {string} with title {string} and status {string}') do |company, title, status|
  url = "https://example.com/#{company.parameterize}-#{SecureRandom.hex(3)}"

  @managed_app = JobApplication.create!(
    url: url,
    company: company,
    title: title,
    status: status
  )
end

When('I update the status of {string} to {string}') do |company, new_status|
  app = JobApplication.find_by!(company: company)

  if app.respond_to?(:push_status!)
    app.push_status!(new_status)
  else
    app.update!(status: new_status)
  end
end

Then('the status of {string} should be {string}') do |company, expected_status|
  app = JobApplication.find_by!(company: company)
  expect(app.status).to eq(expected_status)
end

When('I delete the job application for {string}') do |company|
  app = JobApplication.find_by!(company: company)
  app.destroy!
end

Then('the job application for {string} should not exist') do |company|
  expect(JobApplication.find_by(company: company)).to be_nil
end
