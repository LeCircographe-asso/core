# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Events", type: :request do
  describe "GET /events/:id" do
    context "when the event is a draft" do
      let(:event) { create(:event, status: :draft) }

      it "returns 404 for an anonymous visitor" do
        get event_path(event)
        expect(response).to have_http_status(:not_found)
      end

      it "is visible to an admin previewing it" do
        login_as(create(:user, :admin))

        get event_path(event)
        expect(response).to have_http_status(:success)
      end
    end

    context "when the event is published" do
      let(:event) { create(:event, status: :published) }

      it "returns 200 for an anonymous visitor" do
        get event_path(event)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /events/upcoming" do
    it "excludes drafts" do
      draft = create(:event, :upcoming, status: :draft)
      published = create(:event, :upcoming, status: :published)

      get upcoming_events_path

      expect(response.body).to include(published.title)
      expect(response.body).not_to include(draft.title)
    end
  end
end
