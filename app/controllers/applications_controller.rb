# app/controllers/applications_controller.rb
class ApplicationsController < ApplicationController
  # 前后端分离接口：避免 CSRF 阻断 JSON 调用
  protect_from_forgery with: :null_session

  GHOST_DAYS = (ENV["GHOST_DAYS"] || "21").to_i

  # ------------ CRUD ------------
  def index
    apps = JobApplication.order(created_at: :desc)
    respond_to do |fmt|
      fmt.json { render json: apps.as_json(only: [:id, :url, :company, :title, :status]) }
      fmt.html { redirect_to jobs_path }  # 直接回到主页面，避免渲出不期望的 HTML
    end
  end

  def create
    url = params[:url].to_s.strip
    return render(json: { error: "url required" }, status: 400) if url.blank?

    company = params[:company].to_s.strip
    title   = params[:title].to_s.strip
    status  = params[:status].presence || "Applied"

    company = company.presence || infer_company_from_url(url)
    title   = title.presence   || "(unknown title)"

    # 初始状态一并保存
    app = JobApplication.new(url: url, company: company, title: title, status: status)

    if app.save
      # 如果模型支持 push_status!（用于写入 history），尝试记录一次
      begin
        app.push_status!(status) if status.present?
      rescue NoMethodError
        # 如果没有 push_status! 就忽略，不影响主流程
      end

      render json: app.as_json(only: [:id, :url, :company, :title, :status]), status: :created
    else
      render json: { error: app.errors.full_messages.join(", ") }, status: 422
    end
  end

  def update
    app = JobApplication.find_by(id: params[:id])
    return render(json: { error: "not found" }, status: 404) unless app

    # 优先状态流转：保持你原有的历史追踪逻辑
    if params[:status].present?
      app.push_status!((params[:status]))  # 会同时更新当前 status（按你的模型实现）
      return render json: app.as_json(only: [:id, :url, :company, :title, :status])
    end

    if app.update(app_update_params)
      render json: app.as_json(only: [:id, :url, :company, :title, :status])
    else
      render json: { error: app.errors.full_messages.join(", ") }, status: 422
    end
  end

  def destroy
    app = JobApplication.find_by(id: params[:id])
    return head :no_content unless app
    app.destroy!
    head :no_content
  end

  # ------------ Sankey 统计 ------------
  def stats
    apps = JobApplication.all

    round_labels = Set.new
    apps.find_each do |a|
      Array(a.history).each do |h|
        lab = stage_label(h["status"])
        round_labels << lab if lab.start_with?("Round")
      end
    end
    rounds = round_labels.to_a.sort_by { |x| x[/\d+/].to_i.nonzero? || 1 }

    nodes = ["Applications"] + rounds + ["Offer", "Accepted", "Declined", "Ghosted"]
    idx   = nodes.each_with_index.to_h

    counts = Hash.new(0)
    klass  = {}

    add = lambda do |u, v, cls|
      su, sv = idx[u], idx[v]
      return unless su && sv
      key = [su, sv]
      counts[key] += 1
      klass[key] = cls
    end

    apps.find_each do |a|
      path = canonical_path(a.history, a.status)
      path.each_cons(2) do |u, v|
        cls =
          if u == "Applications" && v.start_with?("Round") then "apps_to_round"
          elsif u == "Applications" && v == "Ghosted"      then "apps_to_ghosted"
          elsif u.start_with?("Round") && v.start_with?("Round") then "round_to_round"
          elsif u.start_with?("Round") && v == "Offer"      then "round_to_offer"
          elsif u.start_with?("Round") && v == "Ghosted"    then "round_to_ghosted"
          elsif u == "Offer" && v == "Accepted"             then "offer_to_accepted"
          elsif u == "Offer" && v == "Declined"             then "offer_to_declined"
          elsif u == "Offer" && v == "Ghosted"              then "offer_to_ghosted"
          else "other"
          end
        add.call(u, v, cls)
      end
    end

    source, target, value, cls = [], [], [], []
    counts.each do |(i, j), w|
      source << i; target << j; value << w; cls << klass[[i, j]]
    end

    render json: { nodes: nodes, links: { source: source, target: target, value: value, cls: cls } }
  end

  private

  def app_update_params
    params.permit(:company, :title, :url, :status)
  end

  def infer_company_from_url(url)
    host = URI.parse(url).host.to_s.downcase.sub(/^www\./, "")
    if host.include?("greenhouse")
      m = url.match(%r{boards\.greenhouse\.io/([^/]+)/})
      return m[1].tr("-", " ").capitalize if m
    elsif host.include?("lever.co")
      seg = URI.parse(url).path.split("/").reject(&:blank?).first
      return seg.tr("-", " ").capitalize if seg
    end
    host.split(".")[-2].to_s.capitalize
  rescue
    "Unknown"
  end

  # 将各种口径的状态映射到规范阶段
  def stage_label(raw)
    s = raw.to_s.strip.downcase
    return "Applications" if s.blank? || s.include?("applied") || s.include?("application")
    if s =~ /\bround\s*(\d+)\b/
      n = Regexp.last_match(1)
      return "Round#{n}"
    end
    if s =~ /(interview|screen|assessment|challenge|take[-\s]?home|phone|onsite|oa|online\s*assessment)/
      return "Round1"
    end
    return "Offer"    if s.include?("offer")
    return "Accepted" if s.include?("accept")
    return "Declined" if s.include?("declin") || s.include?("reject")
    return "Ghosted"  if s.include?("ghost") || s.include?("no answer") || s.include?("no_offer") || s.include?("no offer")
    "Applications"
  end

  def canonical_path(history, current_status)
    steps  = Array(history).sort_by { |h| h["ts"].to_s }
    labels = steps.map { |h| stage_label(h["status"]) }
    labels << stage_label(current_status) if labels.last.to_s != stage_label(current_status)
    labels = labels.chunk_while { |a, b| a == b }.map(&:first)
    labels.unshift("Applications") unless labels.first == "Applications"

    order = Hash.new(0)
    order["Applications"] = 0
    labels.select { |x| x.start_with?("Round") }.uniq
          .sort_by { |x| x[/\d+/].to_i }
          .each_with_index { |r, i| order[r] = 1 + i }
    order["Offer"]    = 100
    order["Accepted"] = 101
    order["Declined"] = 101
    order["Ghosted"]  = 102

    mono, last = [], -1
    labels.each do |st|
      pos = order[st] || 0
      next if mono.last == st
      if pos >= last
        mono << st
        last = pos
      end
    end

    last_ts =
      begin
        Time.parse(steps.last&.dig("ts").to_s)
      rescue
        nil
      end
    if last_ts && (Time.now.utc - last_ts) / 86_400.0 >= GHOST_DAYS
      mono << "Ghosted" unless %w[Accepted Declined Ghosted].include?(mono.last)
    end

    mono
  end
end
