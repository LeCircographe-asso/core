# frozen_string_literal: true

require 'rails_helper'

RSpec.describe People::ContributionUpgrader do
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

        result = described_class.new(
          person: person,
          from_contribution_id: person.contributions.first.id,
          to_formula_id: to_plan.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(true)
        expect(result.new_contribution).to be_present
        expect(result.payment).to be_present
        expect(result.credit_applied).to be >= 0
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
        expect(result.message).to include('Record not found')
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
        expect(result.message).to include('Record not found')
      end
    end
  end
end
