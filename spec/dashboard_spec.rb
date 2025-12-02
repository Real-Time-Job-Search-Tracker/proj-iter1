require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let!(:user) { User.create!(username: "alice", email: "alice@example.com", password: "password", password_confirmation: "password") }

  def login_as(user, password: "password")
    # Fix: Updated parameter to match your new controller logic
    post sign_in_path, params: { email_or_username: user.email, password: password }
    expect(response).to redirect_to(/#{Regexp.escape(dashboard_path)}|\/jobs/)
    follow_redirect!
  end

  describe "GET /dashboard (show)" do
    context "when not logged in" do
      it "renders the demo dashboard (200 OK)" do
        get dashboard_path
        # Fix: Demo mode allows guests to view the dashboard (200 OK), not redirect
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Dashboard")
      end
    end

    context "when logged in" do
      it "renders the user dashboard" do
        login_as(user)
        get dashboard_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Dashboard")
      end
    end
  end

  # Note: Removed GET /stats test because data is now embedded in the show page
end
