# frozen_string_literal: true

require "rails_helper"

RSpec.describe People::MembershipUpgrader do
  describe "#call" do
    let(:person) { create(:person, :without_membership) }
    let(:basic_type) { create(:membership_type, :basic, price_cents: 1000) }
    let(:circus_type) { create(:membership_type, :circus, price_cents: 2500) }
    let(:admin_user) { create(:user, :admin) }

    before do
      create(:membership, :active, :current, person: person, membership_type: basic_type)
    end

    it "upgrades active membership and creates payment" do
      result = described_class.new(
        person: person,
        new_membership_type_id: circus_type.id,
        payment_method: "cash",
        recorded_by_id: admin_user.id
      ).call

      expect(result.success?).to be(true)
      expect(result.membership.membership_type).to eq(circus_type)
      expect(result.payment).to be_present
      expect(result.payment.payment_lines.sole.description).to eq(
        "Passage d'adhésion : #{basic_type.name} -> #{circus_type.name}"
      )
    end

    it "adds an optional donation line to the payment" do
      result = described_class.new(
        person: person,
        new_membership_type_id: circus_type.id,
        payment_method: "cash",
        recorded_by_id: admin_user.id,
        donation_cents: 500
      ).call

      expect(result.success?).to be(true)
      expect(result.payment.total_cents).to eq(circus_type.price_cents + 500)
      expect(result.payment.payment_lines.pluck(:item_type, :amount_cents)).to contain_exactly(
        [ "Membership", circus_type.price_cents ],
        [ "Donation", 500 ]
      )
    end

    it "persists offer_reason for an offered upgrade" do
      super_admin = create(:user, :super_admin)

      result = described_class.new(
        person: person,
        new_membership_type_id: circus_type.id,
        payment_method: "offered",
        recorded_by_id: super_admin.id,
        offer_reason: "Solidarity"
      ).call

      expect(result.success?).to be(true)
      expect(result.payment.payment_method).to eq("offered")
      expect(result.payment.total_cents).to eq(0)
      expect(result.payment.offer_reason).to eq("Solidarity")
      expect(result.payment.payment_lines.pluck(:item_type, :amount_cents)).to contain_exactly(
        [ "Membership", 0 ]
      )
    end

    it "fails with invalid params" do
      result = described_class.new(
        person: person,
        payment_method: "cash",
        recorded_by_id: admin_user.id
      ).call

      expect(result.success?).to be(false)
      expect(result.message).to include(I18n.t("services.validation.invalid_data"))
    end
  end
end
