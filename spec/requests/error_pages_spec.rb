# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Error pages", type: :request do
  describe "routing 404 (catch-all)" do
    it "carries the noindex header" do
      get "/this-route-does-not-exist-xyz"

      expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
    end
  end

  describe "ActiveRecord::RecordNotFound 404 (e.g. Model.find on a bad id)" do
    # Rails renders this via ActionDispatch::PublicExceptions, a fresh response built
    # outside the controller — ApplicationController#set_robots_header never runs, so
    # only a noindex meta tag baked into public/404.html itself protects this path.
    it "still keeps the page out of search results via a meta tag" do
      get "/events/999999"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('<meta name="robots" content="noindex, nofollow" />')
    end
  end

  describe "public/500.html" do
    it "carries a noindex meta tag" do
      expect(File.read(Rails.public_path.join("500.html")))
        .to include('<meta name="robots" content="noindex, nofollow" />')
    end
  end
end
