# frozen_string_literal: true

require "rails_helper"

RSpec.describe People::MembershipUpdater do
  describe "#call" do
    let(:person) { create(:person, :without_membership) }
    let(:old_type) { create(:membership_type, :basic) }
    let(:new_type) { create(:membership_type, :circus) }
    let(:membership) { create(:membership, :active, :current, person: person, membership_type: old_type) }
    let(:admin_user) { create(:user, :admin) }

    it "updates membership type and dates" do
      result = described_class.new(
        membership: membership,
        membership_type_id: new_type.id,
        started_at: Date.current - 2.days,
        ended_at: Date.current + 10.months,
        updated_by_id: admin_user.id
      ).call

      expect(result.success?).to be(true)
      expect(membership.reload.membership_type).to eq(new_type)
      expect(membership.started_at).to eq(Date.current - 2.days)
    end

    it "fails when non-admin tries to update membership" do
      volunteer = create(:user, :volunteer)
      result = described_class.new(
        membership: membership,
        membership_type_id: new_type.id,
        updated_by_id: volunteer.id
      ).call

      expect(result.success?).to be(false)
      expect(result.message).to include(I18n.t("services.errors.insufficient_permissions.membership_update"))
      expect(membership.reload.membership_type).to eq(old_type)
    end
  end
end
