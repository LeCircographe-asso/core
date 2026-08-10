# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users#unsubscribe_by_token", type: :request do
  describe "GET /newsletter/unsubscribe/:token" do
    context "with a valid token" do
      let(:subscriber) { create(:newsletter_subscriber, :subscribed) }

      it "is accessible without authentication and unsubscribes the subscriber" do
        get newsletter_unsubscribe_path(token: subscriber.unsubscribe_token)

        expect(response).to redirect_to(page_path("newsletter_unsubscribe_success"))
        expect(subscriber.reload).not_to be_subscribed
      end
    end

    context "with an invalid token" do
      it "redirects to root with an alert instead of raising" do
        get newsletter_unsubscribe_path(token: "does-not-exist")

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
