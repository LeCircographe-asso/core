# frozen_string_literal: true

require "rails_helper"

RSpec.describe People::MembershipDeactivator do
  describe "#call" do
    let(:person) { create(:person, :without_membership) }
    let(:membership_type) { create(:membership_type, :basic) }
    let(:membership) { create(:membership, :active, :current, person: person, membership_type: membership_type) }
    let(:admin_user) { create(:user, :admin) }

    it "deactivates membership for admin" do
      result = described_class.new(
        membership: membership,
        deactivated_by_id: admin_user.id,
        reason: "manual cleanup"
      ).call

      expect(result.success?).to be(true)
      expect(membership.reload.status).to eq("inactive")
    end

    it "fails for insufficient permissions" do
      volunteer = create(:user, :volunteer)

      result = described_class.new(
        membership: membership,
        deactivated_by_id: volunteer.id,
        reason: "manual cleanup"
      ).call

      expect(result.success?).to be(false)
      expect(result.message).to include(I18n.t("services.errors.insufficient_permissions.membership_deactivate"))
      expect(membership.reload.status).to eq("active")
    end
  end
end
