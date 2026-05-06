# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Partners", type: :request do
  describe "GET /partners" do
    context "format HTML" do
      it "redirige vers la page about" do
        get partners_path
        expect(response).to redirect_to(page_path("about"))
      end
    end

    context "format turbo_stream" do
      it "retourne un turbo stream" do
        get partners_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end
end
