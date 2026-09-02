# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Partners", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "GET /admin/partners" do
    it "returns http success" do
      get admin_partners_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/partners" do
    it "creates a Partner" do
      expect do
        post admin_partners_path, params: { partner: { name: "La Grainerie" } }
      end.to change(Partner, :count).by(1)

      expect(response).to redirect_to(admin_partners_path)
    end

    it "re-renders the form when invalid" do
      expect do
        post admin_partners_path, params: { partner: { name: "" } }
      end.not_to change(Partner, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "is forbidden for a volunteer" do
      login_as(create(:user, :volunteer))

      expect do
        post admin_partners_path, params: { partner: { name: "La Grainerie" } }
      end.not_to change(Partner, :count)
    end
  end

  describe "PATCH /admin/partners/:id" do
    it "updates the Partner" do
      partner = create(:partner)

      patch admin_partner_path(partner), params: { partner: { category: "Lieu associé" } }

      expect(response).to redirect_to(admin_partners_path)
      expect(partner.reload.category).to eq("Lieu associé")
    end
  end

  describe "PATCH /admin/partners/reorder" do
    it "updates display_order from the given ids order" do
      first = create(:partner, display_order: 1)
      second = create(:partner, display_order: 2)

      patch reorder_admin_partners_path, params: { ids: [ second.id, first.id ] }

      expect(response).to have_http_status(:ok)
      expect(second.reload.display_order).to eq(1)
      expect(first.reload.display_order).to eq(2)
    end
  end

  describe "DELETE /admin/partners/:id" do
    it "destroys the Partner" do
      partner = create(:partner)

      expect do
        delete admin_partner_path(partner)
      end.to change(Partner, :count).by(-1)

      expect(response).to redirect_to(admin_partners_path)
    end
  end
end
