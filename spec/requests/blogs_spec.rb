# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Blogs", type: :request do
  describe "GET /blogs (index)" do
    it "is accessible without authentication" do
      get newsletter_blogs_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /blogs/:id (show)" do
    let(:blog) { create(:blog) }

    it "is accessible without authentication" do
      get blog_path(blog)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /blogs/latest" do
    it "is accessible without authentication" do
      get latest_blogs_path

      expect(response).to have_http_status(:ok)
    end
  end
end
