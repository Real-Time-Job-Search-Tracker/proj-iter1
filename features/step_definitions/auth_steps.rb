Given('a user exists with email {string} and password {string}') do |email, password|
  # TO-DO
  @user = User.find_or_create_by!(email: email) do |u|
    u.password = password
    u.password_confirmation = password if u.respond_to?(:password_confirmation)
  end
end

When('I visit the sign in page') do
  # TO-DO
  visit new_user_session_path
end

When('I sign in as {string} with password {string}') do |email, password|
  # TO-DO
  fill_in 'Email', with: email
  fill_in 'Password', with: password
  click_button 'Log in'
  @current_user = User.find_by(email: email)
end

Then('I should see {string}') do |content|
  # TO-DO
  expect(page).to have_content(content)
end

Given('I am signed in as {string} with password {string}') do |email, password|
  # TO-DO
  step %{a user exists with email "#{email}" and password "#{password}"}
  visit new_user_session_path
  fill_in 'Email', with: email
  fill_in 'Password', with: password
  click_button 'Log in'
  @current_user = User.find_by(email: email)
  expect(page).to have_content('Dashboard').or have_content('Signed in successfully')
end
