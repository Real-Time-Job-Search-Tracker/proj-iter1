require "json"

When('I paste {string} into the Add Application form') do |url|
  visit dashboard_path

  expect(page).to have_css("form#new_application", wait: 10)

  find("#application_url", wait: 10).set(url)
end

When("I submit the form") do
  if page.has_button?("Add Application", wait: 1)
    click_button "Add Application"
  else
    find("input[type='submit'][value='Add Application']", wait: 10).click
  end
end

Then('I should see {string} within the applications list') do |company|
  if page.has_css?("#applications", visible: :all)
    within("#applications", visible: :all) do
      expect(page).to have_css("li", text: company, visible: :all, wait: 10)
    end
    next
  end

  expect(page).to have_css("#apps-body", visible: :all, wait: 15)
  expect(page).to have_css("#apps-body tr", text: company, visible: :all, wait: 15)
end

Then('I should see the stage {string} for {string}') do |stage, company|
  if page.has_css?("#applications", visible: :all)
    within("#applications", visible: :all) do
      li = find("li[data-company='#{company}']", visible: :all, wait: 10)
      expect(li).to have_css(".stage", text: stage, visible: :all, wait: 10)
    end
    next
  end

  expect(page).to have_css("#apps-body", visible: :all, wait: 15)
  row = find("#apps-body tr", text: company, visible: :all, wait: 15)
  expect(row).to have_text(stage)
end

Then("I should not see {string}") do |text|
  if page.has_css?("#applications", visible: :all)
    within("#applications", visible: :all) do
      expect(page).to have_no_css("li", text: text, visible: :all, wait: 10)
    end
  end

  if page.has_css?("#apps-body", visible: :all)
    expect(page).to have_no_css("#apps-body tr", text: text, visible: :all, wait: 10)
  else
    expect(page).to have_no_text(text)
  end
end
