# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Contributions", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:person) { create(:person, :with_circus_membership) }
  let(:from_formula) { create(:contribution_formula, :pack10) }
  let(:to_formula) { create(:contribution_formula, :trimester) }
  let!(:existing_contribution) do
    People::ContributionCreator.new(
      person: person,
      contribution_formula_id: from_formula.id,
      payment_method: "cash",
      recorded_by_id: admin.id
    ).call.contribution
  end

  before { login_as(admin) }

  describe "POST /admin/contributions/upgrade" do
    it "upgrades using canonical params" do
      expect do
        post upgrade_admin_contributions_path, params: {
          person_id: person.id,
          from_contribution_id: existing_contribution.id,
          to_formula_id: to_formula.id,
          payment_method: "cash"
        }
      end.to change(Payment, :count).by(1)

      expect(response).to redirect_to(admin_member_path(person))
      expect(person.reload.contributions.order(:created_at).last.contribution_formula).to eq(to_formula)
    end

    it "upgrades using legacy from_book_id and to_plan_id params" do
      expect do
        post upgrade_admin_contributions_path, params: {
          person_id: person.id,
          from_book_id: existing_contribution.id,
          to_plan_id: to_formula.id,
          payment_method: "cash"
        }
      end.to change(Payment, :count).by(1)

      expect(response).to redirect_to(admin_member_path(person))
      expect(person.reload.contributions.order(:created_at).last.contribution_formula).to eq(to_formula)
    end
  end
end
