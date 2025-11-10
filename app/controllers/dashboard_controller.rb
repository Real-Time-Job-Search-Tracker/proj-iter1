class DashboardController < ApplicationController
  before_action :require_login

  def show; end


  def stats
    apps = JobApplication.all
    render json: Sankey::Builder.call(apps)
  end

  private

  def require_login
    redirect_to sign_in_path, alert: "Please sign in" unless current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
  helper_method :current_user
end
