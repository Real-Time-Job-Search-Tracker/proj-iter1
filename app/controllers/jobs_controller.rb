require "httparty"
require "nokogiri"

class JobsController < ApplicationController
  protect_from_forgery with: :null_session

  def index
    @gmail_enabled = false
    @gmail_connected = false
  end

  def inspect
    url = params[:url]
    return render json: { error: "Missing URL" }, status: :bad_request if url.blank?

    begin
      response = HTTParty.get(url, headers: { "User-Agent" => "Mozilla/5.0" }, timeout: 10)
      html = response.body
      doc = Nokogiri::HTML(html)

      title = doc.at("title")&.text&.strip || "Unknown Title"
      company = doc.at('meta[property="og:site_name"]')&.[]("content")&.strip || "Unknown Company"

      render json: { url: url, title: title, company: company }
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end
end
