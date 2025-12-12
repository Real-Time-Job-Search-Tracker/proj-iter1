require "rails_helper"

RSpec.describe ProfilesController, type: :controller do
  let!(:user) do
    User.create!(
      username: "robert",
      email: "robert@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  before do
    # bypass auth + provide current_user
    allow(controller).to receive(:require_login).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #show" do
    it "responds successfully" do
      get :show
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH #update" do
    it "redirects to root with notice when update succeeds" do
      patch :update, params: {
        user: {
          username: "newname",
          daily_goal: 5,
          student_track: "BME",
          default_job_title: "Engineer",
          custom_job_title: "Robotics Engineer"
        }
      }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Profile updated")
      expect(user.reload.username).to eq("newname")
    end

    it "renders 422 and sets flash.now alert when update fails" do
      allow(user).to receive(:update).and_return(false)
      allow(user).to receive_message_chain(:errors, :full_messages).and_return(["Bad stuff"])

      patch :update, params: { user: { username: "anything" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).not_to be_redirect
      expect(flash[:alert]).to eq("Bad stuff")
    end
  end

  describe "PATCH #update_password" do
    it "redirects with alert when current password is incorrect" do
      patch :update_password, params: {
        current_password: "wrong",
        new_password: "NewPassword123!",
        new_password_confirmation: "NewPassword123!"
      }

      expect(response).to redirect_to(profile_path)
      expect(flash[:alert]).to eq("Current password is incorrect")
    end

    it "redirects with alert when new password is blank" do
      patch :update_password, params: {
        current_password: "Password123!",
        new_password: "",
        new_password_confirmation: ""
      }

      expect(response).to redirect_to(profile_path)
      expect(flash[:alert]).to eq("New password cannot be blank")
    end

    it "redirects with alert when confirmation does not match" do
      patch :update_password, params: {
        current_password: "Password123!",
        new_password: "NewPassword123!",
        new_password_confirmation: "Mismatch"
      }

      expect(response).to redirect_to(profile_path)
      expect(flash[:alert]).to eq("Password confirmation does not match")
    end

    it "updates password and redirects with notice when successful" do
      allow(user).to receive(:authenticate).and_return(true)
      allow(user).to receive(:update).with(password: "NewPassword123!").and_return(true)

      patch :update_password, params: {
        current_password: "Password123!",
        new_password: "NewPassword123!",
        new_password_confirmation: "NewPassword123!"
      }

      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to eq("Password updated")
    end


    it "redirects with model errors when update fails" do
      # Pass authenticate, then force update failure
      allow(user).to receive(:authenticate).and_return(true)
      allow(user).to receive(:update).and_return(false)
      allow(user).to receive_message_chain(:errors, :full_messages).and_return(["Update failed"])

      patch :update_password, params: {
        current_password: "Password123!",
        new_password: "NewPassword123!",
        new_password_confirmation: "NewPassword123!"
      }

      expect(response).to redirect_to(profile_path)
      expect(flash[:alert]).to eq("Update failed")
    end
  end
end
