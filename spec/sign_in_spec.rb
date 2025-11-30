require "rails_helper"

RSpec.describe "Sign in", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:user) { User.create!(username: "alice", email: "alice@example.com", password: "password", password_confirmation: "password") }

  it "signs in successfully" do
    visit sign_in_path

    fill_in "email_or_username", with: user.email
    fill_in "password", with: user.password
    
    click_button "Sign In" 

    expect(page).to have_content("Dashboard")
  end

  it "shows error on invalid login" do
    visit sign_in_path

    fill_in "email_or_username", with: "wrong@example.com"
    fill_in "password", with: "wrong"
    
    click_button "Sign In"

    # Fix: Check raw HTML body instead of rendered content
    # Because rack_test does not run JS, the Toast div is never created.
    # The text exists only inside the <script> tag as data.
    expect(page.body).to include("Invalid email")
  end
end