require "rails_helper"

RSpec.describe "Applications", type: :request do
  let!(:job_app) { JobApplication.create!(url: "https://ex.com/del", company: "DelCo", title: "Dev") }

  describe "GET /applications" do
    context "when no JobApplication records exist" do
        before { JobApplication.delete_all }

        it "calls load_fake_jobs and returns sliced fake jobs" do
        # stub load_fake_jobs to control what it returns
        fake_data = [
            { id: 99, url: "https://fake.io/a", company: "FakeCo", title: "Tester", status: "Applied", history: [] },
            { id: 100, url: "https://fake.io/b", company: "FauxCorp", title: "QA", status: "Round1", history: [] }
        ]

        allow_any_instance_of(ApplicationsController)
            .to receive(:load_fake_jobs).and_return(fake_data)

        # request JSON
        get "/applications", as: :json

        # validate JSON response
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to be_a(Array)
        expect(json.size).to eq(2)
        expect(json).to all(include("id", "url", "company", "title", "status"))

        # ensure it matches the stubbed fake job data (sliced fields)
        expect(json.first).to eq({
            "id" => 99,
            "url" => "https://fake.io/a",
            "company" => "FakeCo",
            "title" => "Tester",
            "status" => "Applied"
        })
        end
    end

    context "when JobApplication records exist" do
        it "returns persisted rows" do
        JobApplication.create!(url: "https://ex.com/a", company: "ACME", title: "SWE")
        get "/applications", as: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body.any? { |h| h["company"] == "ACME" }).to be true
        end
    end
  end

  describe "POST /applications" do
    it "rejects invalid URL" do
        post "/applications", params: { url: "not-a-url" }
        expect(response).to have_http_status(:found)
        expect(flash[:alert]).to eq("Please enter a valid URL")
    end

    it "creates with minimal fields and returns JSON when requested as JSON" do
        post "/applications",
            params: { url: "https://ex.com/job1", company: "ACME", title: "Engineer" },
            as: :json

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["company"]).to eq("ACME")
        expect(body["status"]).to eq("Applied")
    end

    it "enriches company/title via parse_job_page when fields are blank" do
        url = "https://jobs.example.com/enrich"
        parsed_result = { company: "EnrichCorp", title: "Software Intern" }

        allow_any_instance_of(ApplicationsController)
        .to receive(:parse_job_page)
        .with(url)
        .and_return(parsed_result)

        post "/applications", params: { url: url, company: "", title: "" }, as: :json
        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["company"]).to eq("EnrichCorp")
        expect(json["title"]).to eq("Software Intern")
    end

    it "handles failed save gracefully, sets flash[:alert], and returns JSON error" do
      allow_any_instance_of(JobApplication).to receive(:save).and_return(false)
      allow_any_instance_of(JobApplication)
        .to receive_message_chain(:errors, :full_messages)
        .and_return([ "URL can't be blank" ])

      post "/applications",
          params: {
            url:     "https://jobs.example.com/failure",
            company: "ErrCo",
            title:   "BadJob"
          },
          as: :json

      expect(response).to have_http_status(:unprocessable_entity)

      body = JSON.parse(response.body)
      expect(body).to eq("error" => "URL can't be blank")
    end
  end


  describe "PATCH /applications/:id" do
    let!(:patch_app) { JobApplication.create!(url: "https://ex.com/j1", company: "Foo", title: "Dev") }

    context "when status is provided" do
      it "calls push_status! and returns JSON with the new status" do
        expect_any_instance_of(JobApplication).to receive(:push_status!).with("Round1").and_call_original

        patch "/applications/#{patch_app.id}", params: { status: "Round1" }, as: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("Round1")
      end
    end

    context "when updating other attributes" do
      it "updates the record and returns JSON" do
        patch "/applications/#{patch_app.id}", params: { company: "NewCo", title: "Senior Engineer" }, as: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["company"]).to eq("NewCo")
        expect(body["title"]).to eq("Senior Engineer")
      end
    end

    it "returns 404 JSON when not found" do
      patch "/applications/999999", params: { company: "Ghost" }, as: :json
      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("not found")
    end
  end

  describe "DELETE /applications/:id" do
    it "deletes when present" do
      app = JobApplication.create!(url: "https://ex.com/z", company: "Zed", title: "Eng")
      delete "/applications/#{app.id}", as: :json
      expect(response).to have_http_status(:no_content)
      expect(JobApplication.exists?(app.id)).to be false
    end

    it "is no-op (204) when missing" do
      delete "/applications/999999", as: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /applications/stats" do
    it "returns nodes and an array of link objects" do
      get "/applications/stats", as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["nodes"]).to be_a(Array)
      expect(json["nodes"]).to include("Applications", "Applied", "Offer")

      expect(json["links"]).to be_a(Array)
      expect(json["links"]).to all(include("source", "target", "value", "cls"))

      pair_keys = json["links"].map { |h| [ h["source"], h["target"] ] }
      expect(pair_keys.uniq.size).to eq(json["links"].size)
    end
  end

  # ---- Private helpers ----
  describe "private helpers" do
    it "#collect_rounds_from_histories extracts and sorts Round labels" do
      histories = [
        [ { "status" => "round 2" }, { "status" => "applied" } ],
        [ { "status" => "Round1" } ],
        [ { "status" => "Interview" } ]
      ]
      ctrl = ApplicationsController.new
      rounds = ctrl.send(:collect_rounds_from_histories, histories)
      expect(rounds).to eq(%w[Round1 Round2])
    end

    it "#build_links_from_paths produces {source,target,value,cls} links from stage paths" do
      nodes = %w[Applications Applied Round1 Offer Accepted Declined Ghosted]
      paths = [
        %w[Applications Applied Round1 Offer Accepted],
        %w[Applications Applied Round1 Offer Declined],
        %w[Applications Applied Round1 Ghosted],
        %w[Applications Applied]
      ]

      ctrl  = ApplicationsController.new
      links = ctrl.send(:build_links_from_paths, paths, nodes)

      expect(links).to be_a(Array)
      expect(links).to all(include(:source, :target, :value, :cls))

      idx = nodes.each_with_index.to_h
      expect(
        links.any? { |h| h[:source] == idx["Applications"] && h[:target] == idx["Applied"] && h[:value] >= 1 }
      ).to be true

      classes = links.map { |h| h[:cls] }
      expect(classes).to include("round_to_offer", "offer_to_accepted", "offer_to_declined", "round_to_ghosted")
      expect(classes).to include("other")
    end

    it "#parse_job_page extracts company/title from og: tags and rescues errors" do
      html = <<~HTML
        <html><head>
          <meta property="og:site_name" content="ACME Corp">
          <meta property="og:title" content="Senior Engineer">
        </head><body></body></html>
      HTML

      allow(HTTParty).to receive(:get).with("https://example.com/job").and_return(double(body: html))
      ctrl = ApplicationsController.new
      expect(ctrl.send(:parse_job_page, "https://example.com/job"))
        .to eq(company: "ACME Corp", title: "Senior Engineer")

      allow(HTTParty).to receive(:get).and_raise(SocketError)
      expect(ctrl.send(:parse_job_page, "https://bad.example")).to eq({})
    end

    describe "#load_fake_jobs" do
    let(:controller_instance) { ApplicationsController.new }
    let(:fake_path) { Rails.root.join("db", "fake_jobs.json") }

    before do
        allow(File).to receive(:exist?).with(fake_path).and_return(true)
    end

    it "reads an Array payload and returns normalized rows with inferred company and defaults" do
        json = [
        {
            "url" => "https://ex.com/a",
            "company" => "A Co",
            "title" => "Engineer",
            "status" => "Round1",
            "history" => [ { "status" => "Applied", "ts" => Time.now.utc.iso8601 } ]
        },
        {
            # company missing -> inferred from Greenhouse URL
            "url" => "https://boards.greenhouse.io/acme/jobs/12345",
            "title" => "Data Scientist",
            "history" => [ "Applied", { "status" => "Round1", "ts" => Time.now.utc.iso8601 } ]
        },
        {
            # title missing -> becomes "(unknown title)"
            "url" => "https://example.org/b",
            "company" => "B Co",
            "status" => "Ghosted",
            "history" => []
        }
        ].to_json

        allow(File).to receive(:read).with(fake_path).and_return(json)

        rows = controller_instance.send(:load_fake_jobs)
        expect(rows).to be_an(Array)
        expect(rows.size).to eq(3)

        rows.each do |h|
        expect(h.keys).to include(:id, :url, :company, :title, :status, :history)
        end

        # inferred company from greenhouse
        gh = rows.find { |h| h[:url].include?("greenhouse") }
        expect(gh[:company]).to eq("Acme")

        # default title when missing
        missing_title = rows.find { |h| h[:url].include?("example.org") }
        expect(missing_title[:title]).to eq("(unknown title)")
    end

    it 'supports a Hash payload with "history" array and still returns normalized rows' do
        json = {
        "history" => [
            { "url" => "https://lever.co/foo/role", "title" => "Backend", "status" => "Applied", "history" => [] },
            { "url" => "https://ex.io/x", "company" => "X Inc", "title" => "FE", "history" => [] }
        ]
        }.to_json

        allow(File).to receive(:read).with(fake_path).and_return(json)

        rows = controller_instance.send(:load_fake_jobs)
        expect(rows).to be_an(Array)
        expect(rows.size).to eq(2)
        expect(rows.first.keys).to include(:id, :url, :company, :title, :status, :history)
    end

    it "returns [] when file missing or unreadable" do
        allow(File).to receive(:exist?).with(fake_path).and_return(false)
        expect(controller_instance.send(:load_fake_jobs)).to eq([])
    end
    end

    describe "#infer_company_from_url" do
      let(:controller_instance) { ApplicationsController.new }

      it "extracts org from Greenhouse boards URLs" do
          url = "https://boards.greenhouse.io/acme/jobs/12345"
          expect(controller_instance.send(:infer_company_from_url, url)).to eq("Acme")
      end

      it "extracts org from Lever URLs" do
          url = "https://jobs.lever.co/super-corp/abc123"
          expect(controller_instance.send(:infer_company_from_url, url)).to eq("Super corp")
      end

      it "falls back to second-level domain" do
          url = "https://careers.example.com/posting/42"
          expect(controller_instance.send(:infer_company_from_url, url)).to eq("Example")
      end

      it "returns 'Unknown' on garbage" do
          url = "not a url at all"
          expect(controller_instance.send(:infer_company_from_url, url)).to eq("Unknown")
      end
    end

    describe "#canonical_path" do
      let(:controller_instance) { ApplicationsController.new }

      it "sorts by ts, dedupes consecutive, prepends Applications, inserts Applied, and appends current status" do
          history = [
          { "status" => "round 1", "ts" => "2024-03-10T12:00:00Z" },
          { "status" => "applied",  "ts" => "2024-03-01T12:00:00Z" },
          { "status" => "round 1", "ts" => "2024-03-11T12:00:00Z" }
          ]
          current = "offer"

          path = controller_instance.send(:canonical_path, history, current)

          # starts with Applications, ensures Applied is present at index 1
          expect(path.first).to eq("Applications")
          expect(path[1]).to eq("Applied")

          # rounds deduped and ordered by ts, then current status added
          normalized = path.map { |s| s.gsub(/\s+/, "") }
          expect(normalized).to include("Round1")
          expect(path).to include("Offer")
          # no consecutive duplicates
          expect(path.each_cons(2).any? { |a, b| a == b }).to be false
      end

      it "does not duplicate Applications or Applied if already present in correct order" do
          history = [
          { "status" => "Applied", "ts" => "2024-01-01T00:00:00Z" },
          { "status" => "Round1",  "ts" => "2024-01-02T00:00:00Z" }
         ]
          current = "Round1"

          path = controller_instance.send(:canonical_path, history, current)
          expect(path.take(3)).to eq(%w[Applications Applied Round1])
      end
    end
  end
end
