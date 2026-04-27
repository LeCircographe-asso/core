require "rails_helper"

RSpec.describe "Admin::Users::Payments", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:person) { create(:person) }

  before { login_as(admin_user) }

  describe "POST /admin/users/:id/payments" do
    let(:membership_type) { create(:membership_type, :circus) }
    let(:membership) { create(:membership, person: person, membership_type: membership_type) }
    let(:contribution_formula) { create(:contribution_formula, :pack10) }

    it "creates a multi-line payment and redirects back to the person dashboard" do
      membership
      contribution_formula

      expect do
        post admin_user_payments_path("person_#{person.id}"), params: {
          payment: {
            payment_method: "cash",
            notes: "Membership + Pack"
          },
          payment_lines: [
            { item_type: "Membership", item_id: membership.id, amount_cents: 3_000, description: "Membership" },
            { item_type: "SubscriptionPlan", item_id: contribution_formula.id, amount_cents: 5_000, description: "Pack 10 sessions" }
          ]
        }
      end.to change(Payment, :count).by(1)
        .and change(PaymentLine, :count).by(2)

      expect(response).to redirect_to(admin_user_path("person_#{person.id}"))

      follow_redirect!
      expect(response.body).to include("Paiement créé avec succès")

      payment = Payment.order(:created_at).last
      expect(payment.total_cents).to eq(8_000)
      expect(payment.payment_lines.map(&:description)).to contain_exactly("Membership", "Pack 10 sessions")
      expect(payment.recorded_by).to eq(admin_user)
    end
  end

  describe "DELETE /admin/users/:id/payments/:payment_id" do
    it "cancels the payment via the deleter service" do
      payment = create(:payment, :success, person: person, recorded_by: admin_user, notes: "Initial note")

      expect do
        delete admin_user_payment_path("person_#{person.id}", payment)
      end.not_to change(Payment, :count)

      expect(response).to redirect_to(admin_user_path("person_#{person.id}"))

      payment.reload
      expect(payment.status).to eq("cancel")
      expect(payment.notes).to include("Cancelled: Suppression via interface admin")
    end
  end
end
