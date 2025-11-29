class DashboardController < ApplicationController
  def show
    if signed_in? && current_user
      @demo_mode   = false
      @apps        = current_user.job_applications.order(created_at: :desc)
      @application = current_user.job_applications.new
    else

      @demo_mode   = true
      session[:guest_apps] = []
      @apps        = []
    end
  end
end
