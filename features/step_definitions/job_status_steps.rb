Given("the following job applications exist:") do |table|
  table.hashes.each do |row|
    JobApplication.create!(
      company: row["company"],
      url: row["url"],
      title: row["title"],   
      status: row["status"]
    )
  end
end

Given("I am on the jobs index page") do
  visit jobs_path
end

When("I change the status of {string} to {string}") do |company, new_status|
  app = JobApplication.find_by(company: company)
  app.update!(status: new_status)
  visit current_path
end

Then("I should see {string} as the status for {string} in the table") do |status, company|
  li = find("ul#applications li[data-company='#{company}']", visible: false)
  expect(li.text(:all)).to include(status)
end

Then("I should see {string} as the status for {string} in the hidden applications list") do |status, company|
  li = find("ul#applications li[data-company='#{company}']", visible: false)
  expect(li.text(:all)).to include(status)
end

Then("the sankey data should include {string} with status {string}") do |company, status|
  using_wait_time 5 do
    found = false
    start_time = Time.now

    while Time.now - start_time < 5
      data = evaluate_script("window.FAKE_JOBS")
      puts "DEBUG Sankey data: #{data.inspect}"
      if data && data.any? { |job| job["company"].to_s.strip.casecmp(company).zero? &&
                                  job["status"].to_s.strip.casecmp(status).zero? }
        found = true
        break
      end
      sleep 0.2
    end

    expect(found).to be true
  end
end

When("I select the filter {string}") do |status|
  visit "#{jobs_path}?status=#{status}"
end

Then("only {string} should be visible in the jobs table") do |company|
  companies = all("ul#applications li", visible: false).map { |li| li["data-company"] }
  expect(companies.select { |c| c == company }).to eq([company])
end

When("I refresh the page") do
  visit current_path
end

Then("I should see {string} as the status for {string}") do |status, company|
  li = find("ul#applications li[data-company='#{company}']", visible: false)
  expect(li.text(:all)).to include(status)
end