
require "set"
require "json"
require "uri"
require "time"

class ApplicationsController < ApplicationController
  skip_forgery_protection only: %i[create update destroy stats]

  GHOST_DAYS = (ENV["GHOST_DAYS"] || "21").to_i
  def index
    if signed_in?
      apps = current_user.job_applications.order(created_at: :desc)

      rows =
        if apps.exists?
          apps.as_json(only: %i[id url company title status])
        else
          []
        end
    else
      extra = (session[:guest_apps] || [])
      rows  = base + extra.map { |h| h.slice("id", "url", "company", "title", "status") }
    end

    render json: rows
  end

  def stats
    begin
      if signed_in?
        apps = current_user.job_applications

        if apps.exists?
          rows = apps.map { |app| { "status" => app.status, "history" => app.history } }
          render json: build_sankey_from_rows(rows), status: :ok
        else
          nodes = %w[Applications Applied Offer Accepted Declined Ghosted]
          render json: { nodes: nodes, links: [] }, status: :ok
        end
      else
        base  = load_fake_jobs
        extra = (session[:guest_apps] || [])
        rows  = base + extra

        render json: build_sankey_from_rows(rows), status: :ok
      end
    rescue => e
      Rails.logger.error("Applications#stats error: #{e.full_message}")
      render json: { nodes: [], links: [] }, status: :ok
    end
  end

  def create
    Rails.logger.debug("Create params: #{params.inspect}")

    # Extract & normalize params
    url     = (params[:url].presence || params.dig(:application, :url)).to_s.strip
    company = (params[:company].presence || params.dig(:application, :company)).to_s.strip
    title   = (params[:title].presence || params.dig(:application, :title)).to_s.strip
    status  = (params[:status].presence || params.dig(:application, :status)).presence || "Applied"

    # Basic URL validation
    unless url.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
      respond_to do |format|
        format.html do
          flash[:alert] = "Please enter a valid URL"
          redirect_to dashboard_path
        end
        format.json do
          render json: { error: "Please enter a valid URL" }, status: :unprocessable_entity
        end
      end
      return
    end

    # Try to scrape company/title if missing
    if (company.blank? || title.blank?) && url !~ /(greenhouse\.io|lever\.co)/i
      parsed  = parse_job_page(url)
      company = parsed[:company] if company.blank? && parsed[:company].present?
      title   = parsed[:title]   if title.blank?   && parsed[:title].present?
    end

    company = company.presence || infer_company_from_url(url)
    title   = title.presence   || "(unknown title)"

    # ----------------- SIGNED-IN USER -----------------
    if signed_in? && current_user
      app = JobApplication.new(
        url:     url,
        company: company,
        title:   title,
        status:  status,
        user:    current_user
      )

      if app.save
        app.push_status!(status) if app.respond_to?(:push_status!) && status.present?

        respond_to do |fmt|
          fmt.html { redirect_to dashboard_path, notice: "Application added" }
          fmt.json { render json: app.slice(:id, :url, :company, :title, :status), status: :created }
        end
      else
        msg = app.errors.full_messages.to_sentence
        respond_to do |fmt|
          fmt.html { redirect_back fallback_location: dashboard_path, alert: msg }
          fmt.json { render json: { error: msg }, status: :unprocessable_entity }
        end
      end

    # ----------------- GUEST MODE -----------------
    else
      # Session-only demo data; nothing is persisted
      session[:guest_apps] ||= []

      new_id = load_fake_jobs.size + session[:guest_apps].size + 1

      history = [
        { "status" => status, "ts" => Time.now.utc.iso8601 }
      ]

      app_hash = {
        "id"      => new_id,
        "url"     => url,
        "company" => company,
        "title"   => title,
        "status"  => status,
        "history" => history
      }

      session[:guest_apps] << app_hash

      respond_to do |fmt|
        fmt.html do
          flash[:notice] = "Application added (demo only, not saved)"
          redirect_to dashboard_path
        end
        fmt.json do
          render json: app_hash.slice("id", "url", "company", "title", "status"),
                status: :created
        end
      end
    end
  end


  def build_sankey_from_rows(rows)
    histories = rows.map { |r| r[:history] || r["history"] }
    paths     = rows.map { |r| canonical_path(r[:history] || r["history"], r[:status] || r["status"]) }
    rounds    = collect_rounds_from_histories(histories)

    nodes = [ "Applications", "Applied" ] + rounds + [ "Offer", "Accepted", "Declined", "Ghosted" ]
    nodes.uniq!
    links = build_links_from_paths(paths, nodes)

    { nodes: nodes, links: links }
  end


  def update
    if signed_in?
      app = current_user.job_applications.find_by(id: params[:id])
      return render(json: { error: "not found" }, status: 404) unless app

      if params[:status].present? && app.respond_to?(:push_status!)
        app.push_status!(params[:status])
        return render json: app.as_json(only: %i[id url company title status])
      end

      if app.update(params.permit(:company, :title, :url, :status))
        render json: app.as_json(only: %i[id url company title status])
      else
        render json: { error: app.errors.full_messages.join(", ") }, status: 422
      end

    else
      guest_apps = session[:guest_apps] || []
      app = guest_apps.find { |h| h["id"].to_s == params[:id].to_s }
      return render(json: { error: "not found" }, status: 404) unless app

      if params[:status].present?
        app["status"] = params[:status]
        (app["history"] ||= []) << { "status" => params[:status], "ts" => Time.now.utc.iso8601 }
      else
        app["company"] = params[:company] if params[:company]
        app["title"]   = params[:title]   if params[:title]
        app["url"]     = params[:url]     if params[:url]
      end

      render json: app.slice("id", "url", "company", "title", "status")
    end
  end

  def destroy
    if signed_in?
      app = current_user.job_applications.find_by(id: params[:id])
      app&.destroy!
    else
      guest_apps = session[:guest_apps] || []
      session[:guest_apps] = guest_apps.reject { |h| h["id"].to_s == params[:id].to_s }
    end

    head :no_content
  end


  private


  def parse_job_page(url)
    require "httparty"
    require "nokogiri"


    headers = {
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }

    response = HTTParty.get(url, headers: headers, timeout: 5)
    return {} unless response.success?

    page = Nokogiri::HTML(response.body)

    company = page.at_css("meta[property='og:site_name']")&.[]("content") ||
              page.at_css("meta[name='application-name']")&.[]("content") ||
              page.at_css(".company-name")&.text&.strip

    title = page.at_css("meta[property='og:title']")&.[]("content") ||
            page.at_css("title")&.text&.strip ||
            page.at_css(".job-title")&.text&.strip


    title = title.split("|").first.strip if title

    { company: company, title: title }
  rescue StandardError => e
    Rails.logger.error("Failed to parse job page: #{e.message}")
    {}
  end

  def load_fake_jobs
    path = Rails.root.join("db", "fake_jobs.json")
    return [] unless File.exist?(path)
    raw = JSON.parse(File.read(path)) rescue []
    arr =
      if raw.is_a?(Hash) && raw["history"].is_a?(Array)
        raw["history"]
      elsif raw.is_a?(Array)
        raw
      else
        []
      end

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
    idx     = nodes.each_with_index.to_h
    counts  = Hash.new(0)
    classes = {}

    add = ->(u, v, cls) do
      su, sv = idx[u], idx[v]
      return unless su && sv
      key = [ su, sv ]
      counts[key]  += 1
      classes[key]  = cls
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

    counts.map do |(source_idx, target_idx), w|
      { source: source_idx, target: target_idx, value: w, cls: classes[[ source_idx, target_idx ]] }
    end
  end

  def humanize_company(slug)
    s = slug.to_s.tr("-", " ").strip
    parts = s.split
    return s if parts.empty?
    first = parts.first.capitalize
    rest  = parts.drop(1).map(&:downcase)
    ([ first ] + rest).join(" ")
  end

  def infer_company_from_url(url)
    uri  = URI.parse(url)
    host = uri.host.to_s.downcase.sub(/^www\./, "")
    path = uri.path.to_s

    if host.include?("greenhouse.io")
      if (m = url.match(%r{boards\.greenhouse\.io/([^/]+)/}i))
        return humanize_company(m[1])
      end
      if (m = url.match(/[\?&]for=([^&]+)/i))
        return humanize_company(CGI.unescape(m[1].to_s))
      end
    end

    if host.end_with?("lever.co")
      seg = path.split("/").reject(&:blank?).first
      return humanize_company(seg) if seg
    end

    base = host.split(".")[-2].to_s
    base.present? ? humanize_company(base) : "Unknown"
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
    labels = Array(history).sort_by { |h| h["ts"].to_s }.map { |h| stage_label(h["status"]) }
    now = stage_label(current_status)
    labels << now if labels.last != now
    labels = labels.chunk_while { |a, b| a == b }.map(&:first)
    labels.unshift("Applications") unless labels.first == "Applications"
    labels.insert(1, "Applied") unless labels.include?("Applied")
    labels
  end
end
