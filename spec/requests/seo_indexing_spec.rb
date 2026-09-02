# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SEO indexing", type: :request do
  describe "X-Robots-Tag header" do
    it "blocks indexing on every response while seo_indexable is disabled" do
      Rails.application.config.x.seo_indexable = false

      get new_session_path

      expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
    end

    it "omits the header once seo_indexable is enabled" do
      Rails.application.config.x.seo_indexable = true

      get new_session_path

      expect(response.headers["X-Robots-Tag"]).to be_nil
    ensure
      Rails.application.config.x.seo_indexable = false
    end
  end
end
