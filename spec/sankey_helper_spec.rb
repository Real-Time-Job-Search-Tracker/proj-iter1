require "rails_helper"

RSpec.describe "Sankey builder" do
  # Helper to build a history item
  def h(status, t = Time.now.utc.iso8601)
    { "status" => status, "ts" => t }
  end

  describe "Sankey::Builder.call" do
    it "returns nodes and a hash of parallel arrays for links (source/target/value/cls)" do
      # App A: only Applied
      a = JobApplication.create!(
        url: "https://example.com/a",
        company: "A Co",
        title: "Eng A",
        status: "Applied",
        history: [ h("Applied") ]
      )

      # App B: Applied -> Round1 -> Offer -> Accepted
      b = JobApplication.create!(
        url: "https://example.com/b",
        company: "B Co",
        title: "Eng B",
        status: "Accepted",
        history: [
          h("Applied",  (Time.now.utc - 3600).iso8601),
          h("Round1",   (Time.now.utc - 1800).iso8601),
          h("Offer",    (Time.now.utc - 600).iso8601)
        ]
      )

      # Pass a relation so find_each works
      apps = JobApplication.where(id: [ a.id, b.id ])
      result = Sankey::Builder.call(apps)

      # nodes
      expect(result).to include(:nodes, :links)
      nodes = result[:nodes]
      expect(nodes).to be_an(Array)
      expect(nodes).to include("Applications", "Applied")
      expect(nodes).to include("Round1", "Offer", "Accepted")

      # links (parallel arrays)
      links = result[:links]
      expect(links).to be_a(Hash)
      %i[source target value cls].each { |k| expect(links).to have_key(k) }
      [ :source, :target, :value, :cls ].each { |k| expect(links[k]).to be_an(Array) }
      expect(links[:source].size).to eq(links[:target].size)
      expect(links[:value].size).to  eq(links[:target].size)
      expect(links[:cls].size).to    eq(links[:target].size)
      expect(links[:source]).not_to be_empty

      idx = nodes.each_with_index.to_h

      # There should be a flow from Applications -> Applied
      edges = links[:source].zip(links[:target], links[:value], links[:cls])
      apps_to_applied = edges.find { |s, t, _v, _c| s == idx["Applications"] && t == idx["Applied"] }
      expect(apps_to_applied).to be_present
      expect(apps_to_applied[2]).to be >= 1  # value

      # And a flow along B's path Round1 -> Offer -> Accepted
      r1_to_offer = edges.find { |s, t, _v, _c| s == idx["Round1"] && t == idx["Offer"] }
      offer_to_acc = edges.find { |s, t, _v, _c| s == idx["Offer"]   && t == idx["Accepted"] }
      expect(r1_to_offer).to be_present
      expect(offer_to_acc).to be_present

      expect(r1_to_offer[2]).to be >= 1
      expect(offer_to_acc[2]).to be >= 1
    end

    it "dedupes consecutive stages in canonical paths (no self-links)" do
      repeated = JobApplication.create!(
        url: "https://example.com/repeated",
        company: "Repeat Co",
        title: "Backend",
        status: "Round1",
        history: [
          h("Applied", (Time.now.utc - 400).iso8601),
          h("Applied", (Time.now.utc - 300).iso8601),
          h("Round1",  (Time.now.utc - 200).iso8601),
          h("Round1",  (Time.now.utc - 100).iso8601)
        ]
      )

      result = Sankey::Builder.call(JobApplication.where(id: repeated.id))
      nodes  = result[:nodes]
      links  = result[:links]

      idx    = nodes.each_with_index.to_h
      edges  = links[:source].zip(links[:target], links[:value])

      # No edge should have the same source/target
      expect(edges.any? { |s, t, _| s == t }).to eq(false)

      # But there should be a progression Applied -> Round1
      a_to_r1 = edges.select { |s, t, _| s == idx["Applied"] && t == idx["Round1"] }
      expect(a_to_r1.sum { |(_, _, v)| v }).to be >= 1
    end
  end

  describe "label normalization" do
    it "capitalizes status strings as implemented (applied -> Applied)" do
      expect(Sankey::Builder.stage_label("applied")).to eq("Applied")
      expect(Sankey::Builder.stage_label("Round1")).to eq("Round1")
      expect(Sankey::Builder.stage_label("phone screen")).to eq("Phone screen")
    end
  end
end
