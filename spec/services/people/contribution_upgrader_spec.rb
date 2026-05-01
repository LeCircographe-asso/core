# frozen_string_literal: true

require 'rails_helper'

RSpec.describe People::ContributionUpgrader do
  include ActiveSupport::Testing::TimeHelpers

  let(:person) { create(:person, :with_circus_membership) }
  let(:admin_user) { create(:user, :admin, person: create(:person)) }
  let(:from_plan) { create(:contribution_formula, :pack10) }
  let(:to_plan) { create(:contribution_formula, :trimester) }
  let(:contribution) do
    People::ContributionCreator.new(
      person: person,
      contribution_formula_id: from_plan.id,
      payment_method: 'cash',
      recorded_by_id: admin_user.id
    ).call.contribution
  end

  describe '#call' do
    context 'with valid attributes' do
      it 'upgrades subscription and returns payment info' do
        contribution # ensure existing pack

        result = nil
        expect do
          result = described_class.new(
            person: person,
            from_contribution_id: person.contributions.first.id,
            to_formula_id: to_plan.id,
            payment_method: 'cash',
            recorded_by_id: admin_user.id
          ).call
        end.to change(Payment, :count).by(1)

        expect(result.success?).to be(true)
        expect(result.new_contribution).to be_present
        expect(result.payment).to be_present
        expect(result.credit_applied).to be >= 0
        expect(result.payment.payment_lines.sum(:amount_cents)).to eq(result.payment.total_cents)
        expect(result.payment.payment_lines.pluck(:item_type).uniq).to eq([ "Contribution" ])
      end

      it 'fires instrumentation' do
        contribution

        upgrader = described_class.new(
          person: person,
          from_contribution_id: person.contributions.first.id,
          to_formula_id: to_plan.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        )

        expect { upgrader.call }.to instrument('contribution.upgraded')
      end

      it 'persists offer_reason for an offered upgrade' do
        contribution
        super_admin = create(:user, :super_admin, person: create(:person))

        result = described_class.new(
          person: person,
          from_contribution_id: person.contributions.first.id,
          to_formula_id: to_plan.id,
          payment_method: 'offered',
          recorded_by_id: super_admin.id,
          offer_reason: 'Solidarity'
        ).call

        expect(result.success?).to be(true)
        expect(result.payment.offer_reason).to eq('Solidarity')
      end

      it 'returns no credit when upgrading from pack10' do
        contribution

        result = described_class.new(
          person: person,
          from_contribution_id: person.contributions.first.id,
          to_formula_id: to_plan.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(true)
        expect(result.old_contribution.reload.status).to eq('suspended')
        expect(result.credit_applied).to eq(0)
      end

      it 'applies prorata credit when upgrading from trimester to annual' do
        travel_to Time.zone.local(2026, 5, 1, 12, 0, 0) do
          annual_plan = create(:contribution_formula, :annual, price_cents: 20_000)
          trimester_plan = create(:contribution_formula, :trimester, price_cents: 6_000)
          trimester_contribution = create(
            :contribution,
            person: person,
            contribution_formula: trimester_plan,
            status: :active,
            expires_at: Date.current + 30.days,
            sessions_remaining: nil
          )

          result = described_class.new(
            person: person,
            from_contribution_id: trimester_contribution.id,
            to_formula_id: annual_plan.id,
            payment_method: 'cash',
            recorded_by_id: admin_user.id
          ).call

          expect(result.success?).to be(true)
          expect(result.old_contribution.reload.status).to eq('suspended')
          expect(result.credit_applied).to eq(2_000)
          expect(result.payment.total_cents).to eq(18_000)
          expect(result.payment.payment_lines.sole.amount_cents).to eq(18_000)
        end
      end
    end

    context 'with invalid data' do
      it 'fails when person missing' do
        result = described_class.new(
          from_contribution_id: 1,
          to_formula_id: to_plan.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include(I18n.t('services.validation.invalid_data'))
      end

      it 'fails when recorded_by missing' do
        result = described_class.new(
          person: person,
          from_contribution_id: 1,
          to_formula_id: to_plan.id,
          payment_method: 'cash'
        ).call

        expect(result.success?).to be(false)
      end

      it 'fails when person has no active circus membership' do
        basic_person = create(:person, :with_basic_membership)
        basic_book = create(:contribution, person: basic_person, contribution_formula: from_plan)

        result = described_class.new(
          person: basic_person,
          from_contribution_id: basic_book.id,
          to_formula_id: to_plan.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Adhésion Cirque active requise')
      end
    end

    context 'with missing records' do
      it 'fails when from_book not found' do
        result = described_class.new(
          person: person,
          from_contribution_id: 999_999,
          to_formula_id: to_plan.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include(I18n.t("services.errors.record_not_found", message: ""))
      end

      it 'fails when to_plan not found' do
        contribution

        result = described_class.new(
          person: person,
          from_contribution_id: person.contributions.first.id,
          to_formula_id: 999_999,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include(I18n.t("services.errors.record_not_found", message: ""))
      end

      it 'fails for an invalid upgrade path' do
        contribution

        result = described_class.new(
          person: person,
          from_contribution_id: person.contributions.first.id,
          to_formula_id: from_plan.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to match(/non autorisé/)
      end
    end
  end
end
