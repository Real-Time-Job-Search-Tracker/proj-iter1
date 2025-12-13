require "rails_helper"

RSpec.describe JobsController, type: :controller do
  describe "GET #index" do
    it "responds successfully" do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #preview" do
    let(:url) { "https://example.com/job" }

    it "returns 400 when url is missing/blank" do
      get :preview, params: { url: "" }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ "error" => "Missing URL" })
    end

    it "fetches the page and returns url/title/company when present" do
      html = <<~HTML
        <html>
          <head>
            <title>  My Job Title  </title>
            <meta property="og:site_name" content="  My Company  " />
          </head>
          <body></body>
        </html>
      HTML

      httparty_response = instance_double("HTTParty::Response", body: html)

      expect(HTTParty).to receive(:get).with(
        url,
        hash_including(
          headers: hash_including("User-Agent" => "Mozilla/5.0"),
          timeout: 10
        )
      ).and_return(httparty_response)

      get :preview, params: { url: url }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to eq(
        "url" => url,
        "title" => "My Job Title",
        "company" => "My Company"
      )
    end

    it 'uses "Unknown Title" and "Unknown Company" when not found' do
      html = <<~HTML
        <html>
          <head></head>
          <body><p>No title/meta here</p></body>
        </html>
      HTML

      httparty_response = instance_double("HTTParty::Response", body: html)
      allow(HTTParty).to receive(:get).and_return(httparty_response)

      get :preview, params: { url: url }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to eq(
        "url" => url,
        "title" => "Unknown Title",
        "company" => "Unknown Company"
      )
    end

    it "returns 500 with the error message if an exception is raised" do
      allow(HTTParty).to receive(:get).and_raise(StandardError, "boom")

      get :preview, params: { url: url }

      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)).to eq({ "error" => "boom" })
    end
  end

  describe "GET #inspect" do
    it "returns hardcoded company/title JSON when job_url is a valid URL" do
      get :inspect, params: { job_url: "https://example.com/jobs/123" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to eq(
        "company" => "ACME Corp",
        "title" => "Senior Engineer – ACME"
      )
    end

    it "returns 422 when job_url is invalid" do
      get :inspect, params: { job_url: "not a url" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq({ "error" => "Invalid job URL" })
    end
  end
end
