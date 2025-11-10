require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) do
    User.create!(
      email: "alice@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  describe "GET /sign_in (Sessions#new)" do
    it "renders the sign in form" do
      get sign_in_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sign in").or include("Email")
    end
  end

  describe "POST /sign_in (Sessions#create)" do
    context "with valid credentials" do
      it "sets the session and redirects to jobs with a notice" do
        post sign_in_path, params: { email: user.email, password: "password" }

        # Success path should redirect to jobs_path per controller
        expect(response).to redirect_to(jobs_path)
        follow_redirect!

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Signed in")
        expect(response.body).to include("Add an application").or include("Applications")
      end

      it "authenticates case-insensitively on email" do
        post sign_in_path, params: { email: "Alice@Example.COM", password: "password" }
        expect(response).to redirect_to(jobs_path)
      end
    end

    context "with invalid credentials" do
      it "re-renders the form with 422 and error message" do
        post sign_in_path, params: { email: user.email, password: "wrong" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Invalid email or password")
      end
    end
  end

  describe "DELETE /sign_out (Sessions#destroy)" do
    it "resets the session and redirects to sign in with a notice" do
      # Log in first (establishes a real session cookie)
      post sign_in_path, params: { email: user.email, password: "password" }
      follow_redirect!

      # Now sign out
      delete sign_out_path
      expect(response).to redirect_to(sign_in_path)
      follow_redirect!

      expect(response.body).to include("Signed out")

      # Behaviorally verify session was cleared: protected page should now redirect
      get dashboard_path
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
