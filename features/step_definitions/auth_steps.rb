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

  within("form.auth-form") do
    fill_in("email_or_username", with: email)
    fill_in("password", with: password)

    # prefer the button label if present; otherwise submit
    if page.has_button?("🚀 Sign In", wait: 0)
      click_button("🚀 Sign In")
    else
      find('button[type="submit"], input[type="submit"]').click
    end
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
