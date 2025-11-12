When('I sign out') do
  click_link "Sign out"
end

Then('I should be on the sign in page') do
  expect(current_path).to eq(sign_in_path)
end
