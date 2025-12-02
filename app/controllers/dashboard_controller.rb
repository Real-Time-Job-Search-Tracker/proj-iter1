class DashboardController < ApplicationController
  def show
    if signed_in? && current_user
      @demo_mode   = false
      @apps        = current_user.job_applications.order(created_at: :desc)
      @application = current_user.job_applications.new
      @sankey_data = Sankey::Builder.call(@apps)

      # ✅ 1. Status Distribution Data (Real)
      # Group by status and count them. Returns { "Applied" => 5, "Offer" => 1, ... }
      @status_data = @apps.group(:status).count

      # ✅ 2. Activity Heatmap Data (Real)
      # Group by applied_on date. Returns { "2023-11-01" => 2, ... }
      @heatmap_data = @apps.group(:applied_on).count

    else
      @demo_mode = true
      @apps = generate_demo_data
      @sankey_data = Sankey::Builder.call(@apps)
      @application = JobApplication.new

      # ✅ 1. Status Distribution Data (Demo)
      @status_data = @apps.group_by(&:status).transform_values(&:count)

      # ✅ 2. Activity Heatmap Data (Demo)
      @heatmap_data = @apps.group_by { |a| a.applied_on.to_s }.transform_values(&:count)
    end
  end

  private

  def generate_demo_data
    require "ostruct"
    companies = %w[Google Meta Netflix Amazon Spotify Uber Airbnb ByteDance]
    titles    = [ "Software Engineer", "Product Manager", "Data Scientist", "Designer" ]

    50.times.map do |i|
      chain = build_random_history_chain
      current_status = chain.last["status"]

      # Generate random dates within the last year for the heatmap
      random_date = Date.today - rand(0..365).days

      OpenStruct.new(
        id: i,
        company: companies.sample,
        title: titles.sample,
        url: "#",
        status: current_status,
        applied_on: random_date, # Use random date
        created_at: Time.now,
        history: chain
      )
    end
  end

  # ... (build_random_history_chain stays the same) ...
  def build_random_history_chain
    chain = [ { "status" => "Applied", "changed_at" => 1.month.ago } ]
    if rand > 0.3
      chain << { "status" => "Round1", "changed_at" => 3.weeks.ago }
      if rand > 0.4
        chain << { "status" => "Round2", "changed_at" => 2.weeks.ago }
        outcome = rand
        if outcome > 0.8
          chain << { "status" => "Offer", "changed_at" => 1.week.ago }
        elsif outcome > 0.5
          chain << { "status" => "Rejected", "changed_at" => 1.week.ago }
        end
      else
        chain << { "status" => "Ghosted", "changed_at" => 2.weeks.ago } if rand > 0.5
      end
    else
       chain << { "status" => "Rejected", "changed_at" => 3.weeks.ago } if rand > 0.5
    end
    chain
  end
end
