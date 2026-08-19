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

    context "when the person already has a member number (reprise after expiration)" do
      let(:person) { create(:person, :with_member_number, :with_expired_membership) }

      it "reissues a new member number and tracks the change in history" do
        old_number = person.member_number

        result = described_class.new(
          person: person,
          membership_type_id: membership_type.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(true)
        expect(result.already_existed).to be(false)
        expect(result.member_number_changed).to be(true)
        expect(result.old_member_number).to eq(old_number)
        expect(result.new_member_number).not_to eq(old_number)

        person.reload
        expect(person.member_number).to eq(result.new_member_number)
        expect(MemberNumberManagement::Policy.valid_format?(person.member_number)).to be(true)

        history = person.member_number_histories.sole
        expect(history.member_number).to eq(person.member_number)
        expect(history.membership_type).to eq("Basique")
        expect(history.replaced_at).to be_nil
      end
    end

    context "when the membership is the person's first (no member number yet)" do
      it "does not report a member number change" do
        result = described_class.new(
          person: person,
          membership_type_id: membership_type.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        ).call

        expect(result.member_number_changed).to be(false)
        expect(result.old_member_number).to be_nil
        expect(result.new_member_number).to be_nil
      end
    end
  end
end
