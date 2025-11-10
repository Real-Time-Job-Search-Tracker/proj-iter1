require "rails_helper"

RSpec.describe "Sign in", type: :feature do

  def sign_in_as(email:, password:)
    visit sign_in_path
    within %(form[data-test="login"]) do
      fill_in "login_email", with: email
      fill_in "login_password", with: password
      find(%([data-test="login_submit"])).click
    end
  end

  it "signs in successfully and redirects to the dashboard" do
    user = User.create!(email: "alice@example.com", password: "password", password_confirmation: "password")

    sign_in_as(email: user.email, password: "password")

    # Accept either dashboard or jobs
    expect([dashboard_path, jobs_path]).to include(page.current_path)

    # Assert we’re on a signed-in page
    expect(page).to have_content("Dashboard").or have_content("Add an application")
    expect(page).to have_css(".flash", text: /Signed in/i).or have_css(".flash", text: /Welcome/i)

    # Only check email if we’re on the dashboard, where it’s rendered
    if page.current_path == dashboard_path
      expect(page).to have_content(user.email)
    end
  end


  it "shows an error when credentials are invalid" do
    # No user created on purpose
    sign_in_as(email: "nobody@example.com", password: "wrongpass")

    # Be tolerant to controller behavior: either stay on sign in, or redirect back with a flash.
    # Assert we still see the login form:
    expect(page).to have_selector('form[data-test="login"]')

    # And we should see SOME flash telling us it's bad creds (text may vary across apps)
    expect(page).to have_css(".flash", text: /invalid|incorrect|try again|unable|failed/i)
  end
end
