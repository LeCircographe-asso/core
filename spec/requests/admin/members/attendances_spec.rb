# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Members::Attendances", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { create(:user, :admin) }
  let(:pack10_plan) { create(:contribution_formula, :pack10) }

  before do
    login_as(admin)
    travel_to Date.current.next_occurring(:tuesday).beginning_of_day + 12.hours
  end

  after { travel_back }

  describe "GET /admin/members/:member_id/attendances/new" do
    it "requires an active circus membership" do
      person = create(:person, :with_basic_membership)

      get new_admin_member_attendance_path(person)

      expect(response.body).to include(I18n.t("admin.members.attendances.needs_membership"))
    end

    it "offers to confirm when a usable contribution exists" do
      person = create(:person, :with_circus_membership)
      create(:contribution, person: person, contribution_formula: pack10_plan, sessions_remaining: 5)

      get new_admin_member_attendance_path(person)

      expect(response.body).to include(I18n.t("admin.members.attendances.confirm_title"))
    end

    it "offers to buy or borrow when there is no usable contribution" do
      person = create(:person, :with_circus_membership)

      get new_admin_member_attendance_path(person)
      text = Nokogiri::HTML.parse(response.body).text

      expect(text).to include(I18n.t("admin.members.attendances.no_usable_contribution"))
      expect(text).to include(I18n.t("admin.members.attendances.lend_prompt"))
    end

    it "lists matching lenders when searching by name" do
      person = create(:person, :with_circus_membership)
      lender = create(:person, :with_circus_membership, first_name: "Camille", last_name: "Dupont")
      create(:contribution, person: lender, contribution_formula: pack10_plan, sessions_remaining: 3)

      get new_admin_member_attendance_path(person, q: "Camille")

      expect(response.body).to include("Camille Dupont")
    end
  end

  describe "POST /admin/members/:member_id/attendances" do
    it "records attendance using the person's own usable contribution" do
      person = create(:person, :with_circus_membership)
      contribution = create(:contribution, person: person, contribution_formula: pack10_plan, sessions_remaining: 5)

      post admin_member_attendances_path(person), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)
      expect(contribution.reload.sessions_remaining).to eq(4)
    end

    it "records attendance borrowing another person's pack10" do
      person = create(:person, :with_circus_membership)
      lender = create(:person, :with_circus_membership)
      contribution = create(:contribution, person: lender, contribution_formula: pack10_plan, sessions_remaining: 3)

      post admin_member_attendances_path(person),
        params: { contribution_id: contribution.id },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)
      expect(contribution.reload.sessions_remaining).to eq(2)
      expect(person.attendances.last.contribution).to eq(contribution)
    end

    it "refuses to borrow a contribution when the recipient has no circus membership" do
      person = create(:person, :with_basic_membership)
      lender = create(:person, :with_circus_membership)
      contribution = create(:contribution, person: lender, contribution_formula: pack10_plan, sessions_remaining: 3)

      post admin_member_attendances_path(person),
        params: { contribution_id: contribution.id },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)
      expect(contribution.reload.sessions_remaining).to eq(3)
    end
  end
end
