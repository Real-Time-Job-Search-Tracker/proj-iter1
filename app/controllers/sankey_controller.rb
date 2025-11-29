class SankeyController < ApplicationController
  def index
    apps =
      if current_user
        current_user.job_applications.order(created_at: :desc)
      else
        JobApplication.none
      end

    render json: Sankey::Builder.call(apps)
  end
end
