# Given("a user exists with email {string} and password {string}") do |email, password|
# User.create!(email: email, password: password, password_confirmation: password)
# end
Given("a user exists with email {string} and password {string}") do |email, password|
  User.create!(
    email: email,
    password: password,
    username: email.split("@").first
  )
end

When("I visit the sign in page") do
  visit(sign_in_path)
end

When("I sign in as {string} with password {string}") do |email, password|
  visit sign_in_path unless current_path == sign_in_path

  within(%(form[data-test="login"])) do
    fill_in "login_email", with: email
    fill_in "login_password", with: password
    find(%([data-test="login_submit"])).click
  end
end

# Given("I am signed in as {string} with password {string}") do |email, password|
# step %(a user exists with email "#{email}" and password "#{password}")
# step %(I sign in as "#{email}" with password "#{password}")
# end
Given("I am signed in as {string} with password {string}") do |email, password|
  step %(a user exists with email "#{email}" and password "#{password}")
  visit sign_in_path
  form = find("form.auth-form", visible: true, wait: 5)
  within(form) do
    fill_in "email_or_username", with: email
    fill_in "password", with: password
    click_button "🚀 Sign In"
  end
end
