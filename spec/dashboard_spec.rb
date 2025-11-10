require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let!(:user) { User.create!(email: "alice@example.com", password: "password", password_confirmation: "password") }

  def login_as(user, password: "password")
    post sign_in_path, params: { email: user.email, password: password }
    expect(response).to redirect_to(/#{Regexp.escape(dashboard_path)}|\/jobs/)
    follow_redirect!
  end

  describe "GET /dashboard (show)" do
    context "when not logged in" do
      it "redirects to sign in with an alert" do
        get dashboard_path
        expect(response).to redirect_to(sign_in_path)
        follow_redirect!
        expect(response.body).to include("Please sign in")
      end
    end

    context "when logged in" do
      it "renders the dashboard" do
        login_as(user)
        get dashboard_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Dashboard")
      end
    end
  end

  describe "GET /stats (dashboard#stats)" do
    context "when not logged in" do
      it "redirects to sign in" do
        get "/stats"
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when logged in" do
      it "returns JSON from Sankey::Builder and passes a relation" do
        a = JobApplication.create!(
          url: "https://example.com/a",
          company: "A Co",
          title: "Eng A",
          status: "Applied",
          history: [ { "status" => "Applied", "ts" => Time.now.utc.iso8601 } ]
        )
        b = JobApplication.create!(
          url: "https://example.com/b",
          company: "B Co",
          title: "Eng B",
          status: "Offer",
          history: [
            { "status" => "Applied", "ts" => (Time.now.utc - 3600).iso8601 },
            { "status" => "Round1",  "ts" => (Time.now.utc - 1800).iso8601 },
            { "status" => "Offer",   "ts" => (Time.now.utc - 600).iso8601 }
          ]
        )

        payload = {
          nodes: %w[Applications Applied Round1 Offer],
          links: { source: [ 0, 1, 2 ], target: [ 1, 2, 3 ], value: [ 2, 1, 1 ], cls: %w[apps_to_applied applied_to_round round_to_offer] }
        }

        expect(Sankey::Builder).to receive(:call) do |relation|
          expect(relation).to be_a(ActiveRecord::Relation)
          expect(relation.pluck(:id)).to include(a.id, b.id)
          payload
        end

        login_as(user)
        get "/stats"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to include("nodes", "links")
        expect(json["nodes"]).to eq(payload[:nodes])
        expect(json["links"]).to include("source", "target", "value", "cls")
      end
    end
  end
end
