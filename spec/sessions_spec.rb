require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { User.create!(username: "alice", email: "alice@example.com", password: "password", password_confirmation: "password") }

  describe "GET /sign_in" do
    it "renders form" do
      get sign_in_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /sign_in" do
    it "logs in with valid credentials" do
      post sign_in_path, params: { email_or_username: "alice@example.com", password: "password" }
      expect(response).to redirect_to(/#{Regexp.escape(dashboard_path)}|\/jobs/)
    end

    it "fails with invalid credentials" do
      post sign_in_path, params: { email_or_username: "wrong", password: "bad" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /sign_out" do
    it "logs out and redirects to root" do
      # Login first
      post sign_in_path, params: { email_or_username: "alice@example.com", password: "password" }
      
      # Then logout
      delete sign_out_path
      
      # Fix: Expect redirect to root_path (/) instead of sign_in_path
      expect(response).to redirect_to(root_path) 
      follow_redirect!
      expect(response.body).to include("Signed out")
    end
  end
end