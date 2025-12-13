# features/step_definitions/common_steps.rb

Then("I should see {string}") do |text|
  expect(page).to have_text(text), -> {
    debug = +"Expected to see: #{text}\n\n"
    debug << "Current path: #{page.current_path}\n\n"
    debug << page.html[0, 4000]
    debug
  }
end

Then("I should be on the dashboard page") do
  expect(page).to have_current_path("/dashboard", ignore_query: true)
end
