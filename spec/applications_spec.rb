# spec/requests/applications_spec.rb
require "rails_helper"

RSpec.describe ApplicationsController, type: :controller do
  let!(:user) do
    User.create!(
      username: "alice",
      email: "alice@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  # ----------------------------
  # Helpers / shared stubs
  # ----------------------------
  def json
    JSON.parse(response.body)
  end

  before do
    # Default to guest unless overwritten in context
    allow(controller).to receive(:signed_in?).and_return(false)
    allow(controller).to receive(:current_user).and_return(nil)
  end

  # ----------------------------
  # INDEX
  # ----------------------------
  describe "GET #index" do
    context "guest (not signed in)" do
      it "returns base + extra rows with applied_on normalized to string" do
        base = [
          { id: 1, url: "https://ex.com/a", company: "ACME", title: "SWE", status: "Applied", applied_on: Date.today.to_s }
        ]
        allow(controller).to receive(:load_fake_jobs).and_return(base)
        session[:guest_apps] = [
          { "id" => 2, "url" => "https://ex.com/b", "company" => "Beta", "title" => "Dev", "status" => "Round1" }
        ]

        get :index, format: :json

        expect(response).to have_http_status(:ok)
        rows = json
        expect(rows.size).to eq(2)
        expect(rows[0]["company"]).to eq("ACME")
        expect(rows[1]["company"]).to eq("Beta")
        expect(rows[0]["applied_on"]).to be_a(String)
        expect(rows[1]["applied_on"]).to be_a(String)
      end
    end

    context "signed in" do
      before do
        allow(controller).to receive(:signed_in?).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "returns [] when user has no applications" do
        rel = instance_double("ActiveRecord::Relation")
        allow(rel).to receive(:order).and_return(rel)
        allow(rel).to receive(:exists?).and_return(false)
        allow(user).to receive(:job_applications).and_return(rel)

        get :index, format: :json

        expect(response).to have_http_status(:ok)
        expect(json).to eq([])
      end

      it "returns persisted rows when applications exist" do
        rel = instance_double("ActiveRecord::Relation")
        allow(rel).to receive(:order).and_return(rel)
        allow(rel).to receive(:exists?).and_return(true)
        allow(rel).to receive(:as_json).and_return([
          { "id" => 10, "url" => "https://ex.com/x", "company" => "ACME", "title" => "SWE", "status" => "Applied", "applied_on" => Date.today.to_s, "created_at" => Time.now.utc.iso8601 }
        ])
        allow(user).to receive(:job_applications).and_return(rel)

        get :index, format: :json

        expect(response).to have_http_status(:ok)
        expect(json.first["company"]).to eq("ACME")
      end
    end
  end

  # ----------------------------
  # STATS
  # ----------------------------
  describe "GET #stats" do
    context "signed in" do
      before do
        allow(controller).to receive(:signed_in?).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "returns empty nodes when no apps exist" do
        rel = instance_double("ActiveRecord::Relation")
        allow(rel).to receive(:exists?).and_return(false)
        allow(user).to receive(:job_applications).and_return(rel)

        get :stats, format: :json

        expect(response).to have_http_status(:ok)
        body = json
        expect(body["nodes"]).to include("Applications", "Applied", "Offer", "Accepted", "Declined", "Ghosted")
        expect(body["links"]).to eq([])
      end

      it "builds sankey when apps exist" do
        rel = instance_double("ActiveRecord::Relation")
        allow(rel).to receive(:exists?).and_return(true)
        allow(rel).to receive(:map).and_return([
          { "status" => "Offer", "history" => [ { "status" => "Applied", "ts" => "2024-01-01T00:00:00Z" } ] }
        ])
        allow(user).to receive(:job_applications).and_return(rel)

        get :stats, format: :json

        expect(response).to have_http_status(:ok)
        body = json
        expect(body["nodes"]).to include("Applications", "Applied", "Offer")
        expect(body["links"]).to be_a(Array)
      end
    end

    context "guest" do
      it "builds sankey from fake + guest session rows" do
        allow(controller).to receive(:load_fake_jobs).and_return([
          { "status" => "Applied", "history" => [ { "status" => "Applied", "ts" => "2024-01-01T00:00:00Z" } ] }
        ])
        session[:guest_apps] = [
          { "status" => "Offer", "history" => [ { "status" => "Round1", "ts" => "2024-01-02T00:00:00Z" } ] }
        ]

        get :stats, format: :json

        expect(response).to have_http_status(:ok)
        body = json
        expect(body["nodes"]).to include("Applications", "Applied", "Offer")
      end
    end

    it "rescues errors and returns {nodes:[], links:[]} with ok" do
      allow(controller).to receive(:signed_in?).and_raise(StandardError, "boom")

      get :stats, format: :json

      expect(response).to have_http_status(:ok)
      expect(json).to eq({ "nodes" => [], "links" => [] })
    end
  end

  # ----------------------------
  # CREATE
  # ----------------------------
  describe "POST #create" do
    it "rejects invalid URL (json) with 422" do
      post :create, params: { url: "not-a-url", company: "X", title: "Y" }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["error"]).to match(/valid URL/i)
    end

    it "rejects invalid URL (html) with redirect + flash" do
      post :create, params: { url: "not-a-url", company: "X", title: "Y" }, format: :html

      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to match(/valid URL/i)
    end

    context "signed in" do
      before do
        allow(controller).to receive(:signed_in?).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "parses company/title when missing and url not greenhouse/lever" do
        allow(controller).to receive(:parse_job_page).and_return({ company: "ParsedCo", title: "ParsedTitle" })
        allow(controller).to receive(:infer_company_from_url).and_call_original

        fake_app = instance_double("JobApplication")
        allow(JobApplication).to receive(:new).and_return(fake_app)
        allow(fake_app).to receive(:save).and_return(true)
        allow(fake_app).to receive(:respond_to?).with(:push_status!).and_return(true)
        expect(fake_app).to receive(:push_status!).with("Applied")
        allow(fake_app).to receive(:slice).and_return(
          { id: 1, url: "https://example.com/job", company: "ParsedCo", title: "ParsedTitle", status: "Applied", applied_on: nil }
        )

        post :create, params: { url: "https://example.com/job", company: "", title: "" }, format: :json

        expect(response).to have_http_status(:created)
        body = json
        expect(body["company"]).to eq("ParsedCo")
        expect(body["title"]).to eq("ParsedTitle")
      end

      it "uses infer_company_from_url + (unknown title) when still missing" do
        allow(controller).to receive(:parse_job_page).and_return({})
        fake_app = instance_double("JobApplication")
        allow(JobApplication).to receive(:new).and_return(fake_app)
        allow(fake_app).to receive(:save).and_return(true)
        allow(fake_app).to receive(:respond_to?).with(:push_status!).and_return(false)
        allow(fake_app).to receive(:slice).and_return(
          { id: 1, url: "https://boards.greenhouse.io/foo/jobs/1", company: "Foo", title: "(unknown title)", status: "Applied", applied_on: nil }
        )

        post :create, params: { url: "https://boards.greenhouse.io/foo/jobs/1", company: "", title: "" }, format: :json

        expect(response).to have_http_status(:created)
        body = json
        expect(body["company"]).to eq("Foo")
        expect(body["title"]).to eq("(unknown title)")
      end

      it "handles save failure (json)" do
        fake_app = instance_double("JobApplication")
        allow(JobApplication).to receive(:new).and_return(fake_app)
        allow(fake_app).to receive(:save).and_return(false)
        allow(fake_app).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return("Nope")

        post :create, params: { url: "https://ex.com/a", company: "A", title: "B" }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["error"]).to eq("Nope")
      end

      it "handles save failure (html)" do
        request.env["HTTP_REFERER"] = dashboard_path

        fake_app = instance_double("JobApplication")
        allow(JobApplication).to receive(:new).and_return(fake_app)
        allow(fake_app).to receive(:save).and_return(false)
        allow(fake_app).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return("Nope")

        post :create, params: { url: "https://ex.com/a", company: "A", title: "B" }, format: :html

        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to eq("Nope")
      end
    end

    context "guest" do
      it "stores in session and returns created json" do
        allow(controller).to receive(:signed_in?).and_return(false)
        allow(controller).to receive(:load_fake_jobs).and_return([ { "id" => 1, "url" => "https://ex.com/base" } ])

        post :create, params: { url: "https://ex.com/new", company: "Co", title: "T", status: "Round1" }, format: :json

        expect(response).to have_http_status(:created)
        body = json
        expect(body["url"]).to eq("https://ex.com/new")
        expect(session[:guest_apps]).to be_an(Array)
        expect(session[:guest_apps].first["history"]).to be_an(Array)
      end

      it "stores in session and redirects html with demo flash" do
        allow(controller).to receive(:load_fake_jobs).and_return([])
        post :create, params: { url: "https://ex.com/new", company: "Co", title: "T" }, format: :html

        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to match(/demo only/i)
      end
    end
  end

  # ----------------------------
  # UPDATE
  # ----------------------------
  describe "PATCH #update" do
    context "signed in" do
      before do
        allow(controller).to receive(:signed_in?).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "returns 404 when not found" do
        rel = instance_double("ActiveRecord::Relation")
        allow(rel).to receive(:find_by).and_return(nil)
        allow(user).to receive(:job_applications).and_return(rel)

        patch :update, params: { id: "999" }, format: :json
        expect(response).to have_http_status(404)
        expect(json["error"]).to eq("not found")
      end

      it "pushes status when status present and push_status! exists" do
        app = instance_double("JobApplication")
        allow(app).to receive(:respond_to?).with(:push_status!).and_return(true)
        expect(app).to receive(:push_status!).with("Round1")
        allow(app).to receive(:as_json).and_return({ "id" => 1, "status" => "Round1" })

        rel = instance_double("ActiveRecord::Relation")
        allow(rel).to receive(:find_by).and_return(app)
        allow(user).to receive(:job_applications).and_return(rel)

        patch :update, params: { id: 1, status: "Round1" }, format: :json
        expect(response).to have_http_status(:ok)
        expect(json["status"]).to eq("Round1")
      end

      it "updates attributes and returns json on success" do
        app = instance_double("JobApplication")
        allow(app).to receive(:respond_to?).with(:push_status!).and_return(false)
        allow(app).to receive(:update).and_return(true)
        allow(app).to receive(:as_json).and_return({ "id" => 1, "title" => "New" })

        rel = instance_double("ActiveRecord::Relation")
        allow(rel).to receive(:find_by).and_return(app)
        allow(user).to receive(:job_applications).and_return(rel)

        patch :update, params: { id: 1, title: "New", applied_on: "2024-01-01" }, format: :json
        expect(response).to have_http_status(:ok)
        expect(json["title"]).to eq("New")
      end

      it "returns 422 with error when update fails" do
        app = instance_double("JobApplication")
        allow(app).to receive(:respond_to?).with(:push_status!).and_return(false)
        allow(app).to receive(:update).and_return(false)
        allow(app).to receive_message_chain(:errors, :full_messages, :join).and_return("Bad")

        rel = instance_double("ActiveRecord::Relation")
        allow(rel).to receive(:find_by).and_return(app)
        allow(user).to receive(:job_applications).and_return(rel)

        patch :update, params: { id: 1, title: "New" }, format: :json
        expect(response).to have_http_status(422)
        expect(json["error"]).to eq("Bad")
      end
    end

    context "guest" do
      it "returns 404 when not found" do
        session[:guest_apps] = [ { "id" => 1, "url" => "https://ex.com/a", "company" => "A" } ]
        patch :update, params: { id: 999, title: "X" }, format: :json
        expect(response).to have_http_status(404)
        expect(json["error"]).to eq("not found")
      end

      it "updates status + appends history when status present" do
        session[:guest_apps] = [ { "id" => 1, "status" => "Applied", "history" => [] } ]
        patch :update, params: { id: 1, status: "Offer" }, format: :json

        expect(response).to have_http_status(:ok)
        body = json
        expect(body["status"]).to eq("Offer")
        expect(session[:guest_apps].first["history"].last["status"]).to eq("Offer")
      end

      it "updates other attributes when status not present" do
        session[:guest_apps] = [ { "id" => 1, "company" => "A", "title" => "T", "url" => "x" } ]
        patch :update, params: { id: 1, company: "B", applied_on: "2024-01-01" }, format: :json

        expect(response).to have_http_status(:ok)
        body = json
        expect(body["company"]).to eq("B")
        expect(body["applied_on"]).to eq("2024-01-01")
      end
    end
  end

  # ----------------------------
  # DESTROY
  # ----------------------------
  describe "DELETE #destroy" do
    context "signed in" do
      before do
        allow(controller).to receive(:signed_in?).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "destroys if present and returns 204" do
        app = instance_double("JobApplication")
        expect(app).to receive(:destroy!)
        rel = instance_double("ActiveRecord::Relation")
        allow(rel).to receive(:find_by).and_return(app)
        allow(user).to receive(:job_applications).and_return(rel)

        delete :destroy, params: { id: 1 }, format: :json
        expect(response).to have_http_status(:no_content)
      end

      it "returns 204 even if not present" do
        rel = instance_double("ActiveRecord::Relation")
        allow(rel).to receive(:find_by).and_return(nil)
        allow(user).to receive(:job_applications).and_return(rel)

        delete :destroy, params: { id: 999 }, format: :json
        expect(response).to have_http_status(:no_content)
      end
    end

    context "guest" do
      it "removes from session and returns 204" do
        session[:guest_apps] = [
          { "id" => 1, "url" => "https://ex.com/a" },
          { "id" => 2, "url" => "https://ex.com/b" }
        ]

        delete :destroy, params: { id: 1 }, format: :json
        expect(response).to have_http_status(:no_content)
        expect(session[:guest_apps].map { |h| h["id"] }).to eq([ 2 ])
      end
    end
  end

  # ----------------------------
  # DIRECT UNIT TESTS FOR HELPERS
  # (to force coverage of all lines)
  # ----------------------------
  describe "helper methods for coverage" do
    it "#infer_company_from_url covers greenhouse/lever/normal/invalid" do
      expect(controller.send(:infer_company_from_url, "https://boards.greenhouse.io/stripe/jobs/1")).to eq("Stripe")
      expect(controller.send(:infer_company_from_url, "https://jobs.lever.co/openai/abc")).to eq("Openai")
      expect(controller.send(:infer_company_from_url, "https://www.google.com/careers")).to eq("Google")
      expect(controller.send(:infer_company_from_url, "not a url")).to eq("Unknown")
    end

    it "#stage_label covers major branches" do
      expect(controller.send(:stage_label, "")).to eq("Applications")
      expect(controller.send(:stage_label, "Applied")).to eq("Applications")
      expect(controller.send(:stage_label, "Round 2")).to eq("Round2")
      expect(controller.send(:stage_label, "Interview")).to eq("Interview")
      expect(controller.send(:stage_label, "Phone Screen")).to eq("Round1")
      expect(controller.send(:stage_label, "Offer")).to eq("Offer")
      expect(controller.send(:stage_label, "Accepted")).to eq("Accepted")
      expect(controller.send(:stage_label, "Declined")).to eq("Declined")
      expect(controller.send(:stage_label, "Ghosted")).to eq("Ghosted")
      expect(controller.send(:stage_label, "No answer")).to eq("Ghosted")
    end

    it "#canonical_path includes Applications + Applied and de-dupes" do
      history = [
        { "status" => "Applied", "ts" => "2024-01-01T00:00:00Z" },
        { "status" => "Applied", "ts" => "2024-01-02T00:00:00Z" },
        { "status" => "Round1",  "ts" => "2024-01-03T00:00:00Z" }
      ]
      path = controller.send(:canonical_path, history, "Offer")
      expect(path.first).to eq("Applications")
      expect(path).to include("Applied")
      expect(path.last).to eq("Offer")
    end

    it "#build_sankey_from_rows produces nodes + links" do
      rows = [
        {
          "status" => "Accepted",
          "history" => [
            { "status" => "Applied", "ts" => "2024-01-01T00:00:00Z" },
            { "status" => "Round1",  "ts" => "2024-01-02T00:00:00Z" },
            { "status" => "Offer",   "ts" => "2024-01-03T00:00:00Z" }
          ]
        }
      ]
      out = controller.build_sankey_from_rows(rows)
      expect(out[:nodes]).to include("Applications", "Applied", "Round1", "Offer", "Accepted")
      expect(out[:links]).to be_an(Array)
    end

    it "#parse_job_page success path (stubbed) and title split" do
      resp = double(success?: true, body: <<~HTML)
        <html>
          <head>
            <meta property="og:site_name" content="MyCo">
            <title>My Role | Careers</title>
          </head>
        </html>
      HTML
      allow(HTTParty).to receive(:get).and_return(resp)

      parsed = controller.send(:parse_job_page, "https://ex.com/job")
      expect(parsed[:company]).to eq("MyCo")
      expect(parsed[:title]).to eq("My Role") # split on "|"
    end

    it "#parse_job_page returns {} when response not success" do
      resp = double(success?: false, body: "")
      allow(HTTParty).to receive(:get).and_return(resp)
      expect(controller.send(:parse_job_page, "https://ex.com/job")).to eq({})
    end

    it "#parse_job_page rescues and returns {}" do
      allow(HTTParty).to receive(:get).and_raise(StandardError, "boom")
      expect(controller.send(:parse_job_page, "https://ex.com/job")).to eq({})
    end

    it "#load_fake_jobs covers: file missing, array payload, hash-with-history payload, weird payload" do
      # missing file => []
      allow(File).to receive(:exist?).and_return(false)
      expect(controller.send(:load_fake_jobs)).to eq([])

      # array payload
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).and_return([ { url: "https://www.google.com", company: "", title: "", status: "" } ].to_json)
      out = controller.send(:load_fake_jobs)
      expect(out).to be_an(Array)
      expect(out.first["company"]).to eq("Google") # inferred
      expect(out.first["title"]).to eq("(unknown title)")

      # hash payload with "history" array
      allow(File).to receive(:read).and_return({ "history" => [ { "url" => "https://jobs.lever.co/openai/x" } ] }.to_json)
      out2 = controller.send(:load_fake_jobs)
      expect(out2.first["company"]).to eq("Openai")

      # weird payload => []
      allow(File).to receive(:read).and_return({ "nope" => 1 }.to_json)
      expect(controller.send(:load_fake_jobs)).to eq([])
    end
  end
end
