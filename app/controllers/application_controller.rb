class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  helper_method :signed_in?
  def signed_in?
    session[:user_id].present?
  end
end
