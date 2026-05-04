# frozen_string_literal: true

require "rails_helper"

RSpec.describe People::MembershipCreator do
  describe "#call" do
    let(:person) { create(:person, :without_membership) }
    let(:membership_type) { create(:membership_type, :basic) }
    let(:admin_user) { create(:user, :admin) }

    it "creates a membership and payment" do
      result = described_class.new(
        person: person,
        membership_type_id: membership_type.id,
        payment_method: "cash",
        recorded_by_id: admin_user.id
      ).call

      expect(result.success?).to be(true)
      expect(result.membership).to be_present
      expect(result.payment).to be_present
    end

    it "returns already_existed when person already has an active membership" do
      create(:membership, :active, :current, person: person, membership_type: membership_type)

      result = described_class.new(
        person: person,
        membership_type_id: membership_type.id,
        payment_method: "cash",
        recorded_by_id: admin_user.id
      ).call

      expect(result.success?).to be(true)
      expect(result.already_existed).to be(true)
      expect(result.payment).to be_nil
    end
  end
end
