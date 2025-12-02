# app/helpers/application_helper.rb
require "set"

module ApplicationHelper
  def collect_rounds_from_histories(histories)
    labs = Set.new
    histories.each do |hist|
      Array(hist).each do |h|
        status = h.is_a?(Hash) ? h["status"] : h
        lab    = stage_label(status)
        labs << lab if lab.start_with?("Round")
      end
    end
    labs.to_a.sort_by { |x| x[/\d+/].to_i.nonzero? || 1 }
  end

  def header_application_count
    if current_user
      current_user.job_applications.count
    else
      JobApplication.where(user_id: nil).count
    end
  end
end
