class SankeyController < ApplicationController
  def index
    render json: {
      nodes: [ "Applied", "Interviewing", "Offer" ],
      links: [
        { source: "Applied", target: "Interviewing", value: 2 },
        { source: "Interviewing", target: "Offer", value: 1 }
      ]
    }
  end
end
