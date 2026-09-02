# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Error pages", type: :request do
  describe "routing 404 (catch-all)" do
    it "carries the noindex header" do
      get "/this-route-does-not-exist-xyz"

      expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
    end
  end

  describe "ActiveRecord::RecordNotFound (e.g. Model.find on a bad id)" do
    # In staging/production, Rails renders this via ActionDispatch::PublicExceptions —
    # a fresh response built outside the controller, so ApplicationController#set_robots_header
    # never runs; only a noindex meta tag baked into public/404.html itself protects this path.
    # Can't assert this end-to-end through a request here: config.consider_all_requests_local
    # is true in test (config/environments/test.rb), so Rails renders its own verbose debug
    # page instead of public/404.html for any unhandled exception — checking the static file's
    # content directly is the only way to cover what actually ships.
    it "still returns a 404 status" do
      get "/events/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "public/404.html and public/500.html (served directly by ActionDispatch::PublicExceptions)" do
    it "both carry a noindex meta tag" do
      %w[404.html 500.html].each do |file|
        expect(File.read(Rails.public_path.join(file)))
          .to include('<meta name="robots" content="noindex, nofollow" />')
      end
    end
  end
end
