# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin zone access", type: :request do
  describe "GET /admin" do
    context "when not signed in" do
      it "redirects to public sign-in" do
        get admin_root_path
        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(flash[:alert]).to eq(I18n.t("admin.base.sign_in_required_alert"))
      end
    end

    context "when signed in as a visitor (no staff role)" do
      let(:user) { create(:user) }

      before { login_as(user) }

      it "redirects to home with a clear staff-only message" do
        get admin_root_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(flash[:alert]).to eq(I18n.t("admin.base.staff_only_alert"))
      end
    end

    context "when signed in as admin" do
      let(:admin) { create(:user, :admin) }

      before { login_as(admin) }

      it "allows the dashboard" do
        get admin_root_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
