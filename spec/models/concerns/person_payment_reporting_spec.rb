# frozen_string_literal: true

require "rails_helper"

RSpec.describe PersonPaymentReporting do
  let(:payer) { create(:person, :with_circus_membership) }
  let(:beneficiary) { create(:person, :with_circus_membership) }
  let(:admin_user) { create(:user, :admin) }
  let(:formula) { create(:contribution_formula, :day) }

  describe "#contribution_purchases_count" do
    it "counts only the contributions that actually belong to the person, not every line of a shared payment" do
      People::ContributionCreator.new(
        person: payer,
        recorded_by_id: admin_user.id,
        payment_method: "cash",
        beneficiaries: [
          { person: payer, contribution_formula_id: formula.id, record_attendance: false },
          { person: beneficiary, contribution_formula_id: formula.id, record_attendance: false }
        ]
      ).call

      expect(payer.contribution_purchases_count).to eq(1)
      expect(beneficiary.contribution_purchases_count).to eq(1)
    end
  end

  describe "offered payments reporting" do
    it "attributes offered counts/totals to the beneficiary, not just the payer" do
      People::ContributionCreator.new(
        person: payer,
        recorded_by_id: admin_user.id,
        payment_method: "offered",
        offer_reason: "Solidarity",
        custom_amount_cents: 0,
        beneficiaries: [
          { person: payer, contribution_formula_id: formula.id, record_attendance: false },
          { person: beneficiary, contribution_formula_id: formula.id, record_attendance: false }
        ]
      ).call

      expect(beneficiary.offered_payments_count).to eq(1)
      expect(beneficiary.offered_payments_total).to eq(0)
      expect(beneficiary.free_offers_count).to eq(1)
      expect(beneficiary.paid_offers_count).to eq(0)
    end

    it "does not attribute another beneficiary's line amount to the payer's total" do
      People::ContributionCreator.new(
        person: payer,
        recorded_by_id: admin_user.id,
        payment_method: "offered",
        offer_reason: "Solidarity",
        custom_amount_cents: 500,
        beneficiaries: [
          { person: payer, contribution_formula_id: formula.id, record_attendance: false },
          { person: beneficiary, contribution_formula_id: formula.id, record_attendance: false }
        ]
      ).call

      # Le paiement total est 1000 (2 x 500), mais chaque bénéficiaire ne "possède" que sa ligne.
      expect(payer.offered_payments_total).to eq(500)
      expect(beneficiary.offered_payments_total).to eq(500)
    end
  end
end
