require "rails_helper"

RSpec.describe People::ContributionCreator do
  let(:person) { create(:person, :with_circus_membership) }
  let(:contribution_formula) { create(:contribution_formula, :pack10) }
  let(:admin_user) { create(:user, :admin, person: create(:person)) }

  describe "#call" do
    context "with valid attributes" do
      let(:params) do
        {
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          record_attendance: false
        }
      end

      it "creates a subscription successfully" do
        result = described_class.new(params).call

        expect(result.success?).to be(true)
        expect(result.contribution).to be_present
        expect(result.payment).to be_present
        expect(result.payment.total_cents).to eq(contribution_formula.price_cents)
      end

      it "fires instrumentation" do
        creator = described_class.new(params)

        expect { creator.call }.to instrument("contribution.created")
      end
    end

    context "with offered payment" do
      it "fails when offer_reason missing" do
        result = described_class.new(
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: "offered",
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
      end

      it "succeeds when super admin provides offer_reason" do
        super_admin = create(:user, :super_admin, person: create(:person))
        result = described_class.new(
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: "offered",
          recorded_by_id: super_admin.id,
          offer_reason: "Solidarity"
        ).call

        expect(result.success?).to be(true)
        expect(result.payment.total_cents).to eq(0)
      end
    end

    context "with invalid data" do
      it "fails when person missing" do
        result = described_class.new(
          contribution_formula_id: contribution_formula.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include("Invalid data")
      end

      it "fails when plan missing" do
        result = described_class.new(
          person: person,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
      end

      it "fails when recorded_by missing" do
        result = described_class.new(
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: "cash"
        ).call

        expect(result.success?).to be(false)
      end
    end

    context "with non circus membership" do
      let(:basic_person) { create(:person) }
      let!(:basic_membership) { create(:membership, person: basic_person, membership_type: create(:membership_type, category: :basic), status: :active) }

      it "fails when person cannot buy subscription plans" do
        result = described_class.new(
          person: basic_person,
          contribution_formula_id: contribution_formula.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include("adhésion Cirque")
      end
    end
  end
end
