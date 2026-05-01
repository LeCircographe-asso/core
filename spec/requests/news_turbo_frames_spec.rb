# frozen_string_literal: true

require "rails_helper"

RSpec.describe "News page Turbo Frames (public)" do
  describe "GET /events/past as turbo-frame" do
    it "renders the matching frame without authentication" do
      get past_events_path, headers: { "Turbo-Frame" => "activities-past" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('turbo-frame id="activities-past"')
    end
  end

  describe "GET /blogs/latest as turbo-frame" do
    it "renders the matching frame without authentication" do
      get latest_blogs_path, headers: { "Turbo-Frame" => "activities-blogs" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('turbo-frame id="activities-blogs"')
    end
  end
end
