# class ApplicationController < ActionController::Base
#   protect_from_forgery with: :exception

#   private

#   helper_method :signed_in?
#   def signed_in?
#     session[:user_id].present?
#   end
# end

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method :signed_in?, :current_user

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def signed_in?
    current_user.present?
  end
end


