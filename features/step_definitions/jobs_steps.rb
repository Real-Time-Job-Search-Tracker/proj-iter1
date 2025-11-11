require 'cgi'
require 'json'

Given("the parser will return job details for {string}") do |url|
  html = <<~HTML
    <html>
      <head>
        <title>Senior Engineer</title>
        <meta property="og:site_name" content="ACME Corp">
      </head>
      <body></body>
    </html>
  HTML

  stub_request(:get, url).to_return(status: 200, body: html, headers: { "Content-Type" => "text/html" })
end

When('I inspect the URL {string}') do |url|
  visit "/jobs/inspect.json?url=#{CGI.escape(url)}"
end

Then('the JSON should include {string}') do |text|
  data = JSON.parse(page.body)
  expect(data.values.join(" ")).to include(text)
end

Then('the JSON should include an error') do
  data = JSON.parse(page.body)
  expect(data["error"]).not_to be_nil
end
