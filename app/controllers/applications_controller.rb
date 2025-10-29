# app/controllers/applications_controller.rb
require "set"
require "json"
require "uri"
require "time"

class ApplicationsController < ApplicationController
  protect_from_forgery with: :null_session

  GHOST_DAYS = (ENV["GHOST_DAYS"] || "21").to_i

  def index
    apps = Application.order(created_at: :desc)

    rows =
      if apps.exists?
        apps.select(:id, :url, :company, :title, :status).map(&:attributes)
      else
        load_fake_jobs.map { |h| h.slice(:id, :url, :company, :title, :status) }
      end

    render json: rows
  end

  def create
    url = params[:url].to_s.strip
    return render(json: { error: "url required" }, status: 400) if url.blank?

    company = params[:company].to_s.strip
    title   = params[:title].to_s.strip
    status  = params[:status].presence || "Applied"

    company = company.presence || infer_company_from_url(url)
    title   = title.presence   || "(unknown title)"

    app = Application.new(url: url, company: company, title: title, status: status)

    if app.save
      app.push_status!(status) if app.respond_to?(:push_status!) && status.present?
      render json: app.as_json(only: [:id, :url, :company, :title, :status]), status: :created
    else
      render json: { error: app.errors.full_messages.join(", ") }, status: 422
    end
  end

  def update
    app = Application.find_by(id: params[:id])
    return render(json: { error: "not found" }, status: 404) unless app

    if params[:status].present? && app.respond_to?(:push_status!)
      app.push_status!(params[:status])
      return render json: app.as_json(only: [:id, :url, :company, :title, :status])
    end

    if app.update(params.permit(:company, :title, :url, :status))
      render json: app.as_json(only: [:id, :url, :company, :title, :status])
    else
      render json: { error: app.errors.full_messages.join(", ") }, status: 422
    end
  end

  def destroy
    app = Application.find_by(id: params[:id])
    app&.destroy!
    head :no_content
  end

  def stats
    apps = Application.all

    if apps.exists?
      round_labels = Set.new
      apps.find_each do |a|
        Array(a.history).each do |h|
          lab = stage_label(h["status"])
          round_labels << lab if lab.start_with?("Round")
        end
      end
      rounds = round_labels.to_a.sort_by { |x| x[/\d+/].to_i.nonzero? || 1 }

      nodes = ["Applications"] + rounds + ["Offer", "Accepted", "Declined", "Ghosted"]
      paths = []
      apps.find_each { |a| paths << canonical_path(a.history, a.status) }
      links = build_links_from_paths(paths, nodes)

      render json: { nodes: nodes, links: links }
    else
      fakes  = load_fake_jobs
      rounds = collect_rounds_from_histories(fakes.map { |h| h[:history] })
      nodes  = ["Applications"] + rounds + ["Offer", "Accepted", "Declined", "Ghosted"]
      paths  = fakes.map { |h| canonical_path(h[:history], h[:status]) }
      links  = build_links_from_paths(paths, nodes)
      render json: { nodes: nodes, links: links }
    end
  end

  private

  def load_fake_jobs
    path = Rails.root.join("db", "fake_jobs.json")
    return [] unless File.exist?(path)
    arr = JSON.parse(File.read(path)) rescue []
    arr = [] unless arr.is_a?(Array)

    arr.each_with_index.map do |x, i|
      h = x.is_a?(Hash) ? x : {}
      url     = (h["url"] || h[:url]).to_s
      company = (h["company"] || h[:company]).to_s
      title   = (h["title"] || h[:title]).to_s
      status  = (h["status"] || h[:status]).to_s.presence || "Applied"
      hist_raw = (h["history"] || h[:history])

      history = Array(hist_raw).map do |e|
        if e.is_a?(Hash)
          { "status" => (e["status"] || e[:status] || e["s"] || e[:s]).to_s,
            "ts"     => (e["ts"] || e[:ts] || e["t"] || e[:t] || Time.now.utc.iso8601).to_s }
        else
          { "status" => e.to_s, "ts" => Time.now.utc.iso8601 }
        end
      end

      company = company.presence || infer_company_from_url(url)
      title   = title.presence   || "(unknown title)"

      { id: i + 1, url: url, company: company, title: title, status: status, history: history }
    end
  end

  def collect_rounds_from_histories(histories)
    labs = Set.new
    histories.each do |hist|
      Array(hist).each do |h|
        lab = stage_label(h["status"])
        labs << lab if lab.start_with?("Round")
      end
    end
    labs.to_a.sort_by { |x| x[/\d+/].to_i.nonzero? || 1 }
  end

  def build_links_from_paths(paths, nodes)
    idx = nodes.each_with_index.to_h
    counts = Hash.new(0)
    klass  = {}

    add = ->(u, v, cls) do
      su, sv = idx[u], idx[v]
      return unless su && sv
      key = [su, sv]
      counts[key] += 1
      klass[key] = cls
    end

    paths.each do |path|
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
    counts.each { |(i, j), w| source << i; target << j; value << w; cls << klass[[i, j]] }
    { source: source, target: target, value: value, cls: cls }
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
    host.split(".")[-2].to_s.presence&.capitalize || "Unknown"
  rescue
    "Unknown"
  end

  def stage_label(raw)
    s = raw.to_s.strip.downcase
    return "Applications" if s.blank? || s.include?("applied") || s.include?("application")
    if s =~ /\bround\s*(\d+)\b/
      return "Round#{Regexp.last_match(1)}"
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
