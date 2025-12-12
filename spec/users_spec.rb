require "rails_helper"

RSpec.describe UsersController, type: :controller do
  describe "GET #new" do
    it "responds successfully" do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        user: {
          username: "robert",
          email: "robert@example.com",
          password: "Password123!",
          password_confirmation: "Password123!"
        }
      }
    end

    it "creates the user, sets session[:user_id], and redirects with notice" do
      expect {
        post :create, params: valid_params
      }.to change(User, :count).by(1)

      created = User.order(:id).last
      expect(session[:user_id]).to eq(created.id)
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:notice]).to eq("Account created")
    end

    it "renders 422 and sets flash.now alert when save fails" do
      # Avoid guessing validations by forcing save failure
      fake_errors = instance_double("ActiveModel::Errors")
      allow(fake_errors).to receive(:full_messages).and_return(["Invalid email"])

      allow_any_instance_of(User).to receive(:save).and_return(false)
      allow_any_instance_of(User).to receive(:errors).and_return(fake_errors)

      post :create, params: valid_params

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).not_to be_redirect
      expect(flash[:alert]).to eq("Invalid email")
      expect(session[:user_id]).to be_nil
    end

    it "only permits expected parameters (extra keys ignored)" do
      post :create, params: {
        user: valid_params[:user].merge(admin: true, role: "owner")
      }

      created = User.order(:id).last
      # The record should still be created (assuming validations pass),
      # but unpermitted keys shouldn't be mass-assigned.
      if created
        expect(created.respond_to?(:admin) ? created.admin : nil).not_to eq(true)
        expect(created.respond_to?(:role) ? created.role : nil).not_to eq("owner")
      end
    end
  end
end
