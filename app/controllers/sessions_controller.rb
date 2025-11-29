class SessionsController < ApplicationController
  def new
    redirect_to dashboard_path if signed_in?
  end

  def create
    login = params[:email_or_username].to_s.strip.downcase
    password = params[:password]

    user =
      User.find_by("LOWER(email) = ?", login) ||
      User.find_by("LOWER(username) = ?", login)

    if user&.authenticate(password)
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Signed in"
    else
      flash.now[:alert] = "Invalid email/username or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out"
  end
end
