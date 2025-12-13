def ensure_user(email, password)
  User.create!(
    email: email,
    username: email.split("@").first,
    password: password,
    password_confirmation: password
  )
rescue ActiveModel::UnknownAttributeError
  User.create!(
    email: email,
    username: email.split("@").first,
    password: password
  )
end

def sign_in(email:, password:)
  visit(sign_in_path)
  expect(page).to have_css("form.auth-form", visible: true, wait: 5)

  within("form.auth-form") do
    fill_in("email_or_username", with: email)
    fill_in("password", with: password)
    click_button("🚀 Sign In")
  end
end

Given("a user exists with email {string} and password {string}") do |email, password|
  ensure_user(email, password)
end

When("I visit the sign in page") do
  visit(sign_in_path)
end

When("I sign in as {string} with password {string}") do |email, password|
  sign_in(email: email, password: password)
end

Given("I am signed in as {string} with password {string}") do |email, password|
  ensure_user(email, password)
  sign_in(email: email, password: password)
end

When("I sign out") do
  if page.has_button?("Sign out", wait: 2)
    click_button("Sign out")
  else
    click_link("Sign out")
  end
end

Then("I should be signed out") do
  expect(page).to have_text("Hi, Guest")
  expect(page).to have_link("Sign in", href: sign_in_path)
  expect(page).not_to have_button("Sign out")
end

Then("I should be on the sign in page") do
  expect([ sign_in_path, "/" ]).to include(page.current_path)
  step %(I should be signed out)
end
