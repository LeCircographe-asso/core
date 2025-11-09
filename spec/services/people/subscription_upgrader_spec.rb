require "rails_helper"

RSpec.describe People::SubscriptionUpgrader do
  let(:person) { create(:person, :with_circus_membership) }
  let(:admin_user) { create(:user, :admin, person: create(:person)) }
  let(:from_plan) { create(:subscription_plan, :pack10) }
  let(:to_plan) { create(:subscription_plan, :trimester) }
  let(:book_of_entry) do
    People::SubscriptionCreator.new(
      person: person,
      subscription_plan_id: from_plan.id,
      payment_method: "cash",
      recorded_by_id: admin_user.id
    ).call.book_of_entry
  end

  describe "#call" do
    context "with valid attributes" do
      it "upgrades subscription and returns payment info" do
        book_of_entry # ensure existing pack

        result = described_class.new(
          person: person,
          from_book_id: person.book_of_entries.first.id,
          to_plan_id: to_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(true)
        expect(result.new_book).to be_present
        expect(result.payment).to be_present
        expect(result.credit_applied).to be >= 0
      end

      it "fires instrumentation" do
        book_of_entry

        upgrader = described_class.new(
          person: person,
          from_book_id: person.book_of_entries.first.id,
          to_plan_id: to_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        )

        expect { upgrader.call }.to instrument("subscription.upgraded")
      end
    end

    context "with invalid data" do
      it "fails when person missing" do
        result = described_class.new(
          from_book_id: 1,
          to_plan_id: to_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include("Invalid data")
      end

      it "fails when recorded_by missing" do
        result = described_class.new(
          person: person,
          from_book_id: 1,
          to_plan_id: to_plan.id,
          payment_method: "cash"
        ).call

        expect(result.success?).to be(false)
      end
    end

    context "with missing records" do
      it "fails when from_book not found" do
        result = described_class.new(
          person: person,
          from_book_id: 999_999,
          to_plan_id: to_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include("Record not found")
      end

      it "fails when to_plan not found" do
        book_of_entry

        result = described_class.new(
          person: person,
          from_book_id: person.book_of_entries.first.id,
          to_plan_id: 999_999,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include("Record not found")
      end
    end
  end
end
