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
  expect([sign_in_path, "/"]).to include(page.current_path)
  step %(I should be signed out)
end
