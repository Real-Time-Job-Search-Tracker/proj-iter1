class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to root_path, notice: "Profile updated"
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end


  def update_password
    @user = current_user

    unless @user.authenticate(params[:current_password])
      redirect_to profile_path, alert: "Current password is incorrect" and return
    end

    if params[:new_password].blank?
      redirect_to profile_path, alert: "New password cannot be blank" and return
    end

    if params[:new_password] != params[:new_password_confirmation]
      redirect_to profile_path, alert: "Password confirmation does not match" and return
    end

    if @user.update(password: params[:new_password])
      redirect_to profile_path, notice: "Password updated"
    else
      redirect_to profile_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  private

  def profile_params
    params.require(:user).permit(
      :username,
      :daily_goal,
      :student_track,
      :default_job_title,
      :custom_job_title,
      :avatar
    )
  end
end
