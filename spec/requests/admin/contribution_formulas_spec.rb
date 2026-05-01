# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ContributionFormulas", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:person) { create(:person, :with_circus_membership) }
  let(:formula) { create(:contribution_formula, :pack10, price_cents: 2_500) }

  before { login_as(admin) }

  describe "POST /admin/contribution_formulas" do
    it "creates a contribution payment with contribution and donation lines" do
      expect do
        post admin_contribution_formulas_path, params: {
          contribution_formula: {
            person_id: person.id,
            contribution_formula_id: formula.id,
            payment_method: "cash",
            donation_amount: "7.00"
          }
        }
      end.to change(Contribution, :count).by(1)
        .and change(Payment, :count).by(1)

      payment = Payment.order(:created_at).last
      contribution = person.contributions.order(:created_at).last

      expect(response).to redirect_to(admin_user_path("person_#{person.id}"))
      expect(payment.total_cents).to eq(3_200)
      expect(payment.payment_lines.pluck(:item_type, :item_id, :amount_cents)).to contain_exactly(
        [ "Contribution", contribution.id, 2_500 ],
        [ "Donation", payment.id, 700 ]
      )
    end

    it "creates an offered contribution payment with persisted offer_reason" do
      super_admin = create(:user, :super_admin)
      login_as(super_admin)

      post admin_contribution_formulas_path, params: {
        contribution_formula: {
          person_id: person.id,
          contribution_formula_id: formula.id,
          payment_method: "offered",
          offer_reason: "Solidarity"
        }
      }

      payment = Payment.order(:created_at).last

      expect(response).to redirect_to(admin_user_path("person_#{person.id}"))
      expect(payment.payment_method).to eq("offered")
      expect(payment.total_cents).to eq(0)
      expect(payment.offer_reason).to eq("Solidarity")
      expect(payment.payment_lines.sole.item_type).to eq("Contribution")
      expect(payment.payment_lines.sole.amount_cents).to eq(0)
    end
  end
end
