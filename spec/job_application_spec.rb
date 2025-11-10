require "rails_helper"

RSpec.describe JobApplication, type: :model do
  describe "validations" do
    it "requires url, company, and title" do
      app = described_class.new
      expect(app).to be_invalid
      expect(app.errors.attribute_names).to include(:url, :company, :title)
    end

    it "enforces url uniqueness" do
      described_class.create!(url: "https://example.com/acme", company: "ACME", title: "Engineer")
      dup = described_class.new(url: "https://example.com/acme", company: "ACME", title: "Engineer")
      expect(dup).to be_invalid
      expect(dup.errors.attribute_names).to include(:url)
    end
  end

  describe "defaults & history on create" do
    it "defaults status to 'Applied' and seeds history with an Applied event" do
      app = described_class.create!(url: "https://example.com/xyz", company: "XYZ", title: "Dev")
      expect(app.status).to eq("Applied")
      expect(app.history).to be_an(Array)
      expect(app.history.size).to be >= 1

      last = app.history.last
      expect(last["status"]).to eq("Applied")
      # ts should be ISO8601
      expect { Time.iso8601(last["ts"]) }.not_to raise_error
    end

    it "keeps an explicitly provided status, but still records an Applied event in history" do
      app = described_class.create!(url: "https://example.com/abc", company: "ABC", title: "SWE", status: "Round1")
      expect(app.status).to eq("Round1")
      expect(app.history.map { |h| h["status"] }).to include("Applied")
    end
  end

  describe "#push_status!" do
    it "updates the current status and appends a history event" do
      app = described_class.create!(url: "https://example.com/foo", company: "Foo Inc", title: "Engineer")
      expect(app.status).to eq("Applied")

      expect {
        app.push_status!("Round1")
      }.to change { app.reload.status }.from("Applied").to("Round1")
       .and change { app.reload.history.size }.by(1)

      last = app.history.last
      expect(last["status"]).to eq("Round1")
      expect { Time.iso8601(last["ts"]) }.not_to raise_error
    end

    it "can be called multiple times to track progression" do
      app = described_class.create!(url: "https://example.com/bar", company: "Bar Co", title: "Backend")
      %w[Round1 Offer Accepted].each { |s| app.push_status!(s) }

      expect(app.status).to eq("Accepted")
      expect(app.history.map { |h| h["status"] }).to include("Applied", "Round1", "Offer", "Accepted")
    end
  end
end