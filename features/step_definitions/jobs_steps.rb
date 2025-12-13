require "cgi"
require "json"

Given('the parser will return job details for {string}') do |url|
  html = <<~HTML
    <html>
      <head>
        <meta property="og:site_name" content="ACME Corp">
        <meta property="og:title" content="Senior Engineer – ACME">
        <title>Senior Engineer – ACME | ACME Corp</title>
      </head>
      <body>
        <h1>Senior Engineer – ACME</h1>
        <div class="company-name">ACME Corp</div>
      </body>
    </html>
  HTML

  stub_request(:get, url)
    .to_return(
      status: 200,
      headers: { "Content-Type" => "text/html" },
      body: html
    )
end

When("I inspect the URL {string}") do |url|
  Capybara.current_driver = :rack_test
  page.driver.header 'Accept', 'application/json'
  visit inspect_job_path(job_url: url)
end

Then('the JSON should include {string}') do |text|
  data = JSON.parse(page.body)
  flat = data.values.map { |v| v.is_a?(String) ? v : v.to_s }.join(" ")
  expect(flat).to include(text)
end

Then('the JSON should include an error') do
  data = JSON.parse(page.body)
  expect(data["error"]).to be_present
end
