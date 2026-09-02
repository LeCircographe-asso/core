# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::BoardMembers", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "GET /admin/board_members" do
    it "returns http success" do
      get admin_board_members_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/board_members" do
    it "creates a BoardMember" do
      expect do
        post admin_board_members_path, params: { board_member: { name: "Léa Martin", role: "Présidente" } }
      end.to change(BoardMember, :count).by(1)

      expect(response).to redirect_to(admin_board_members_path)
    end

    it "re-renders the form when invalid" do
      expect do
        post admin_board_members_path, params: { board_member: { name: "", role: "" } }
      end.not_to change(BoardMember, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "is forbidden for a volunteer" do
      login_as(create(:user, :volunteer))

      expect do
        post admin_board_members_path, params: { board_member: { name: "Léa Martin", role: "Présidente" } }
      end.not_to change(BoardMember, :count)
    end
  end

  describe "PATCH /admin/board_members/:id" do
    it "updates the BoardMember" do
      member = create(:board_member)

      patch admin_board_member_path(member), params: { board_member: { role: "Trésorière" } }

      expect(response).to redirect_to(admin_board_members_path)
      expect(member.reload.role).to eq("Trésorière")
    end
  end

  describe "PATCH /admin/board_members/reorder" do
    it "updates display_order from the given ids order" do
      first = create(:board_member, display_order: 1)
      second = create(:board_member, display_order: 2)

      patch reorder_admin_board_members_path, params: { ids: [ second.id, first.id ] }

      expect(response).to have_http_status(:ok)
      expect(second.reload.display_order).to eq(1)
      expect(first.reload.display_order).to eq(2)
    end
  end

  describe "DELETE /admin/board_members/:id" do
    it "destroys the BoardMember" do
      member = create(:board_member)

      expect do
        delete admin_board_member_path(member)
      end.to change(BoardMember, :count).by(-1)

      expect(response).to redirect_to(admin_board_members_path)
    end
  end
end
