# frozen_string_literal: true

require "rails_helper"

# Admin forms submit amounts in euros ("19.99"). Converting them with
# `(value.to_f * 100).to_i` truncates the float product (1998.9999...) and
# loses one cent. Every entry point below must store exactly 1999 cents.
RSpec.describe "Euro amounts submitted to admin forms", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:person) { create(:person) }

  before { login_as(admin) }

  it "records a donation of 19.99 EUR as 1999 cents" do
    post admin_donations_path, params: { person_id: person.id, payment: { payment_amount: "19.99" } }

    expect(Payment.last.total_cents).to eq(1999)
  end

  it "records a direct payment of 19.99 EUR as 1999 cents" do
    post admin_payments_path, params: {
      payment: { person_id: person.id, total_cents: "19.99", payment_method: "cash" }
    }

    expect(Payment.last.total_cents).to eq(1999)
  end

  it "updates a payment to 19.99 EUR as 1999 cents" do
    payment = create(:payment, :success, person: person, total_cents: 1500)

    patch admin_payment_path(payment), params: { payment: { total_cents: "19.99" } }

    expect(payment.reload.total_cents).to eq(1999)
  end

  it "updates a member payment to 19.99 EUR as 1999 cents" do
    payment = create(:payment, :success, person: person, total_cents: 1500)

    patch admin_member_payment_path(person, payment), params: { payment: { total_cents: "19.99" } }

    expect(payment.reload.total_cents).to eq(1999)
  end

  it "adds a 19.99 EUR donation to a membership sale as 1999 cents" do
    membership_type = create(:membership_type)

    post admin_memberships_path, params: {
      membership: {
        person_id: person.id, membership_type_id: membership_type.id,
        payment_method: "cash", donation_amount: "19.99"
      }
    }

    donation_line = Payment.last.payment_lines.find_by(item_type: "Donation")
    expect(donation_line.amount_cents).to eq(1999)
  end

  it "adds a 19.99 EUR donation to a contribution sale as 1999 cents" do
    circus_person = create(:person, :with_circus_membership)
    formula = create(:contribution_formula, :pack10, membership_type: circus_person.current_membership.membership_type)

    post admin_contributions_path, params: {
      person_id: circus_person.id,
      contribution: { contribution_formula_id: formula.id, payment_method: "cash", donation_amount: "19.99" }
    }

    donation_line = Payment.last.payment_lines.find_by(item_type: "Donation")
    expect(donation_line.amount_cents).to eq(1999)
  end
end
