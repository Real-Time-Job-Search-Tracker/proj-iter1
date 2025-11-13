require "set"
require "json"
require "uri"
require "time"

class ApplicationsController < ApplicationController
  skip_forgery_protection if: -> { request.format.json? }

  GHOST_DAYS = (ENV["GHOST_DAYS"] || "21").to_i

  def index
    apps = JobApplication.order(created_at: :desc)

    rows =
    if apps.exists?
      apps.as_json(only: %i[id url company title status])
    else
      load_fake_jobs.map { |h| h.slice(:id, :url, :company, :title, :status) }
    end

    respond_to do |fmt|
      fmt.json { render json: rows }
      fmt.html { redirect_to root_path }
    end
  end

  def create
    # accept flat or nested form params
    url     = (params[:url].presence || params.dig(:application, :url)).to_s.strip
    company = (params[:company].presence || params.dig(:application, :company)).to_s.strip
    title   = (params[:title].presence || params.dig(:application, :title)).to_s.strip
    status  = (params[:status].presence || params.dig(:application, :status)).presence || "Applied"

    # 1) Validate URL
    unless url.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
      return redirect_to(new_application_path, alert: "Please enter a valid URL")
    end

    # 2) Enrich from the job page if company/title are blank
    if company.blank? || title.blank?
      parsed = parse_job_page(url) # uses HTTParty/Nokogiri (stubbable by your step)
      company = parsed[:company] if company.blank? && parsed[:company].present?
      title   = parsed[:title]   if title.blank?   && parsed[:title].present?
    end

    # 3) Fallback guesses
    company = company.presence || infer_company_from_url(url)
    title   = title.presence   || "(unknown title)"

    app = JobApplication.new(url: url, company: company, title: title, status: status)

    if app.save
      app.push_status!(status) if app.respond_to?(:push_status!) && status.present?

      flash[:notice] = "Application added"
      respond_to do |fmt|
        fmt.html { redirect_to jobs_path }
        fmt.json { render json: app.slice(:id, :url, :company, :title, :status), status: :created }
      end
    else
      Rails.logger.debug("JobApplication save errors: \\#{app.errors.full_messages}")
      msg = app.errors.full_messages.to_sentence
      flash[:alert] = msg
      respond_to do |fmt|
        fmt.html { redirect_back fallback_location: new_application_path, alert: msg }
        fmt.json { render json: { error: msg }, status: :unprocessable_entity }
      end
    end
  end

  def update
    app = JobApplication.find_by(id: params[:id])
    return render(json: { error: "not found" }, status: 404) unless app

    if params[:status].present? && app.respond_to?(:push_status!)
      app.push_status!(params[:status])
      return render json: app.as_json(only: [ :id, :url, :company, :title, :status ])
    end

    if app.update(params.permit(:company, :title, :url, :status))
      render json: app.as_json(only: [ :id, :url, :company, :title, :status ])
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

  def new
    # render form
  end


  def stats
    apps = JobApplication.all

    if apps.exists?
      paths = apps.map { |app| canonical_path(app.history, app.status) }
      rounds = collect_rounds_from_histories(apps.map(&:history))
      nodes  = ["Applications", "Applied"] + rounds + ["Offer", "Accepted", "Declined", "Ghosted"]
      nodes.uniq!
      links  = build_links_from_paths(paths, nodes)
      render json: { nodes: nodes, links: links }
    else
      nodes = ["Applications","Applied","Round1","Round2","Offer","Accepted","Declined","Ghosted"]
      raw_links = {
        source: [0,0,1,2,3,3],
        target: [1,6,2,3,4,5],
        value:  [250,150,120,40,25,15],
        cls:    ["apps_to_round","apps_to_ghosted","round_to_round","round_to_offer","offer_to_accepted","offer_to_declined"]
      }
      links = raw_links[:source].each_with_index.map do |src, i|
        { source: src, target: raw_links[:target][i], value: raw_links[:value][i], cls: raw_links[:cls][i] }
      end
      render json: { nodes: nodes, links: links }
    end
  end

  private

  # Parses the job page to extract company and title details
  def parse_job_page(url)
    require "httparty"
    require "nokogiri"

    response = HTTParty.get(url)
    page = Nokogiri::HTML(response.body)

    # Example parsing logic (adjust selectors based on actual job page structure)
    company = page.at_css("meta[property='og:site_name']")&.[]("content") ||
              page.at_css(".company-name")&.text&.strip

    title = page.at_css("meta[property='og:title']")&.[]("content") ||
            page.at_css(".job-title")&.text&.strip

    { company: company, title: title }
  rescue StandardError => e
    Rails.logger.error("Failed to parse job page: \\#{e.message}")
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

    # Return Array<{source:, target:, value:, cls:}>
    counts.map do |(source_idx, target_idx), w|
      { source: source_idx, target: target_idx, value: w, cls: classes[[ source_idx, target_idx ]] }
    end
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
    labels = Array(history).sort_by { |h| h["ts"].to_s }.map { |h| stage_label(h["status"]) }
    now = stage_label(current_status)
    labels << now if labels.last != now
    labels = labels.chunk_while { |a, b| a == b }.map(&:first)
    labels.unshift("Applications") unless labels.first == "Applications"
    labels.insert(1, "Applied") unless labels.include?("Applied")
    labels
  end
end
