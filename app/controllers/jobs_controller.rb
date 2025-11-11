require "httparty"
require "nokogiri"

class JobsController < ApplicationController
  include ApplicationsController::JobParser 
  
  protect_from_forgery with: :null_session

  def index
    @gmail_enabled = false
    @gmail_connected = false
  end

  def inspect
    url = params[:url].to_s.strip
    
    unless url.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
      return render json: { error: "Please enter a valid URL" }, status: :unprocessable_entity
    end

    begin
      details = parse_job_page(url) 
      render json: details
    rescue => e
      render json: { error: e.message, status: :internal_server_error }
    end
  end
end