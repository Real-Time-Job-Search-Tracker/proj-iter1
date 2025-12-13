# Sends a standard HTML form submission (POST)
When("I send a HTML POST request to {string} with params:") do |path, table|
  params = table.rows_hash
  # Use submit for POST to ensure correct handling
  page.driver.submit(:post, path, params)
end

# Sends a standard HTML form submission (PATCH)
When("I send a HTML PATCH request to {string} with params:") do |path, table|
  params = table.rows_hash
  # FIXED: Use 'submit' method with :patch symbol. 
  # 'page.driver.patch' does not exist in some driver versions.
  page.driver.submit(:patch, path, params)
end

# Follows the 302/303 redirect response
When("I follow the redirect") do
  if page.driver.response.redirect?
    visit page.driver.response.location
  end
end

# Checks if we are on a specific path
Then("I should be redirected to {string}") do |path|
  expect(page.current_path).to eq(path)
end

# Checks for flash messages
Then("I should see a flash message {string}") do |message|
  expect(page.body).to include(message)
end