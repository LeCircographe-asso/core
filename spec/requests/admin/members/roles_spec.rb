# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Members::Roles", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:target) { create(:user) }

  describe "PATCH /admin/members/:member_id/role" do
    it "lets an admin make a web visitor a volunteer" do
      login_as(admin)

      patch admin_member_role_path(target.person), params: { role: { system_role: "volunteer" } }

      expect(response).to redirect_to(admin_member_path(target.person))
      expect(flash[:notice]).to be_present
      expect(target.reload).to be_volunteer
    end

    it "refuses a forged promotion to admin by an admin" do
      login_as(admin)

      patch admin_member_role_path(target.person), params: { role: { system_role: "admin" } }

      expect(flash[:alert]).to eq(I18n.t("services.errors.insufficient_permissions.role_assignment"))
      expect(target.reload).to be_web_visitor
    end

    it "keeps volunteers out" do
      login_as(create(:user, :volunteer))

      patch admin_member_role_path(target.person), params: { role: { system_role: "volunteer" } }

      expect(response).to redirect_to(admin_dashboard_index_path)
      expect(target.reload).to be_web_visitor
    end

    it "explains when the person has no web account" do
      login_as(admin)
      person = create(:person)

      patch admin_member_role_path(person), params: { role: { system_role: "volunteer" } }

      expect(flash[:alert]).to eq(I18n.t("admin.roles.no_web_account"))
    end
  end
end
