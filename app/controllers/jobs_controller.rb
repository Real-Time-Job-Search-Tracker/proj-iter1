require "httparty"
require "nokogiri"

class JobsController < ApplicationController
  def inspect
    url = params[:url]
    return render json: { error: "Missing URL" }, status: :bad_request if url.blank?

    begin
      html = HTTParty.get(url).body
      doc = Nokogiri::HTML(html)

      title = doc.at("title")&.text || "Unknown Title"
      company = doc.at('meta[property="og:site_name"]')&.[]("content") || "Unknown Company"

      render json: { url: url, title: title, company: company }
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end
end
