# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Account claims", type: :request do
  describe "with account claim disabled" do
    around do |example|
      prev = Rails.application.config.x.account_claim_enabled
      Rails.application.config.x.account_claim_enabled = false
      example.run
    ensure
      Rails.application.config.x.account_claim_enabled = prev
    end

    it "redirects GET /account_claims/new to root with flash" do
      get new_account_claim_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("account_claims.disabled_notice"))
    end

    it "redirects GET /account_claims/confirm" do
      get confirm_account_claims_path(token: "any-token")
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("account_claims.disabled_notice"))
    end

    it "redirects POST /account_claims without creating a claim" do
      user = create(:user)
      login_as(user)

      expect do
        post account_claims_path, params: { email: "member@example.com" }
      end.not_to(change { AccountClaim.count })

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("account_claims.disabled_notice"))
    end
  end
end
