Given("a user exists with email {string} and password {string}") do |email, password|
  @current_user = User.find_or_create_by!(email: email) do |user|
    user.password = password
    user.password_confirmation = password
  end
end

When("I visit the sign in page") do
  visit sign_in_path
end

When("I sign in as {string} with password {string}") do |email, password|
  visit sign_in_path unless current_path == sign_in_path

  fill_in "login_email", with: email
  fill_in "login_password", with: password
  click_button "Sign in"
  

  expect(page).to have_current_path(jobs_path, wait: 5)
end

Given("I am signed in as {string} with password {string}") do |email, password|
  step %(a user exists with email "#{email}" and password "#{password}")
  step %(I sign in as "#{email}" with password "#{password}")
end