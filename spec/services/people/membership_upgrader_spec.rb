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
