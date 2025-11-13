When('I sign out') do
  if page.has_button?('Sign out', wait: 1)
    click_button 'Sign out'
  else
    click_link 'Sign out'
  end
end

Then('I should be on the sign in page') do
  expect(page).to have_current_path(sign_in_path, ignore_query: true)
end
