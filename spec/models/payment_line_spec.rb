# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentLine, type: :model do
  describe 'validations' do
    it 'can be created' do
      payment = build_stubbed(:payment)
      membership_type = build_stubbed(:membership_type)
      payment_line = PaymentLine.new(payment: payment, item: membership_type, amount_cents: 1500)
      expect(payment_line).to be_present
    end

    it 'requires a payment' do
      membership_type = build_stubbed(:membership_type)
      payment_line = PaymentLine.new(item: membership_type, amount_cents: 1500)
      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:payment]).to include(I18n.t('errors.messages.required'))
    end

    it 'does not require a backing item record (polymorphic optional)' do
      # Donation lines reference their parent payment id without a Donation model.
      payment = build_stubbed(:payment)
      payment_line = PaymentLine.new(
        payment: payment,
        item_type: 'Donation',
        item_id: payment.id,
        amount_cents: 1500
      )
      expect(payment_line).to be_valid
      expect(payment_line.errors[:item]).to be_empty
    end

    it 'requires amount_cents' do
      payment = build_stubbed(:payment)
      membership_type = build_stubbed(:membership_type)
      payment_line = PaymentLine.new(payment: payment, item: membership_type)
      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:amount_cents]).to include(I18n.t('errors.messages.blank'))
    end

    it 'allows amount_cents to be 0 (for free/offered items)' do
      payment = build_stubbed(:payment)
      membership_type = build_stubbed(:membership_type)
      payment_line = PaymentLine.new(payment: payment, item: membership_type, amount_cents: 0)
      expect(payment_line).to be_valid
    end

    it 'requires item_type' do
      payment = build_stubbed(:payment)
      membership_type = build_stubbed(:membership_type)
      payment_line = PaymentLine.new(payment: payment, item: membership_type, amount_cents: 1500)
      payment_line.item_type = nil
      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:item_type]).to include(I18n.t('errors.messages.blank'))
    end

    it 'requires item_id' do
      payment = build_stubbed(:payment)
      membership_type = build_stubbed(:membership_type)
      payment_line = PaymentLine.new(payment: payment, item: membership_type, amount_cents: 1500)
      payment_line.item_id = nil
      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:item_id]).to include(I18n.t('errors.messages.blank'))
    end

    it 'validates uniqueness of payment_id scoped to item_type and item_id' do
      payment = create(:payment)
      membership_type = create(:membership_type)
      create(:payment_line, payment: payment, item: membership_type, amount_cents: 1500)

      duplicate_line = PaymentLine.new(payment: payment, item: membership_type, amount_cents: 2000)
      expect(duplicate_line).not_to be_valid
      expect(duplicate_line.errors[:payment_id]).to include(I18n.t('errors.messages.taken'))
    end

    it "rejects legacy item_type 'Payment' for donations" do
      payment = build_stubbed(:payment)
      payment_line = PaymentLine.new(
        payment: payment,
        item_type: 'Payment',
        item_id: payment.id,
        amount_cents: 500
      )
      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:item_type]).to include(
        I18n.t('activerecord.errors.models.payment_line.attributes.item_type.not_allowed', value: 'Payment')
      )
    end

    it 'requires a person for Contribution lines (beneficiary)' do
      payment = build_stubbed(:payment)
      contribution = build_stubbed(:contribution)
      payment_line = PaymentLine.new(payment: payment, item: contribution, item_type: 'Contribution', amount_cents: 1500)

      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:person_id]).to include(I18n.t('errors.messages.blank'))
    end

    it 'does not require a person for non-Contribution lines' do
      payment = build_stubbed(:payment)
      membership_type = build_stubbed(:membership_type)
      payment_line = PaymentLine.new(payment: payment, item: membership_type, amount_cents: 1500)

      expect(payment_line).to be_valid
    end

    it 'accepts the canonical Donation item_type' do
      payment = build_stubbed(:payment)
      payment_line = PaymentLine.new(
        payment: payment,
        item_type: 'Donation',
        item_id: payment.id,
        amount_cents: 500
      )
      expect(payment_line).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a payment' do
      payment = build_stubbed(:payment)
      payment_line = described_class.new(payment: payment, item: build_stubbed(:membership_type), amount_cents: 2500)
      expect(payment_line.payment).to eq(payment)
    end

    it 'belongs to a polymorphic item (membership)' do
      membership = build_stubbed(:membership)
      payment_line = described_class.new(payment: build_stubbed(:payment), item: membership, amount_cents: 2500)
      expect(payment_line.item).to eq(membership)
      expect(payment_line.item_type).to eq('Membership')
    end

    it 'belongs to a polymorphic item (contribution_formula)' do
      contribution_formula = build_stubbed(:contribution_formula)
      payment_line = described_class.new(payment: build_stubbed(:payment), item: contribution_formula, amount_cents: 2500)
      expect(payment_line.item).to eq(contribution_formula)
      expect(payment_line.item_type).to eq('ContributionFormula')
    end

    it 'belongs to a polymorphic item (membership_type)' do
      membership_type = build_stubbed(:membership_type)
      payment_line = described_class.new(payment: build_stubbed(:payment), item: membership_type, amount_cents: 2500)
      expect(payment_line.item).to eq(membership_type)
      expect(payment_line.item_type).to eq('MembershipType')
    end
  end

  describe 'scopes' do
    let!(:payment) { create(:payment) }
    let!(:membership_line) { create(:payment_line, payment: payment, item: create(:membership, person: payment.person), item_type: 'Membership') }
    let!(:contribution_formula_line) { create(:payment_line, payment: payment, item: create(:contribution_formula), item_type: 'ContributionFormula') }
    let!(:membership_type_line) { create(:payment_line, payment: payment, item: create(:membership_type), item_type: 'MembershipType') }

    it 'finds membership lines' do
      expect(PaymentLine.memberships).to include(membership_line)
      expect(PaymentLine.memberships).not_to include(contribution_formula_line, membership_type_line)
    end

    it 'finds contribution formula lines' do
      expect(PaymentLine.contribution_formulas).to include(contribution_formula_line)
      expect(PaymentLine.contribution_formulas).not_to include(membership_line, membership_type_line)
    end

    it 'finds membership type lines' do
      expect(PaymentLine.membership_types).to include(membership_type_line)
      expect(PaymentLine.membership_types).not_to include(membership_line, contribution_formula_line)
    end

    it 'finds lines by item type' do
      expect(PaymentLine.by_item_type('Membership')).to include(membership_line)
      expect(PaymentLine.by_item_type('ContributionFormula')).to include(contribution_formula_line)
      expect(PaymentLine.by_item_type('MembershipType')).to include(membership_type_line)
    end
  end

  describe '#item_description' do
    it 'returns description for membership' do
      membership_type = create(:membership_type, name: 'Adhésion Basique')
      membership = build_stubbed(:membership, membership_type: membership_type)
      payment_line = described_class.new(item: membership, item_type: 'Membership', description: nil)

      expect(payment_line.item_description).to eq('Adhésion Basique')
    end

    it 'prefers an explicit description for membership lines' do
      membership_type = create(:membership_type, name: 'Adhésion Cirque Tarif Réduit')
      membership = build_stubbed(:membership, membership_type: membership_type)
      payment_line = described_class.new(
        item: membership,
        item_type: 'Membership',
        description: "Passage d'adhésion : Adhésion Basique -> Adhésion Cirque Tarif Réduit"
      )

      expect(payment_line.item_description).to eq("Passage d'adhésion : Adhésion Basique -> Adhésion Cirque Tarif Réduit")
    end

    it 'returns description for contribution_formula' do
      contribution_formula = build_stubbed(:contribution_formula, name: 'Plan Trimestriel', duration: 'trimester')
      payment_line = described_class.new(item: contribution_formula, item_type: 'ContributionFormula')

      expect(payment_line.item_description).to eq('Trimestriel') # duration_humanized
    end

    it 'returns description for membership_type' do
      membership_type = build_stubbed(:membership_type, name: 'Adhésion Cirque')
      payment_line = described_class.new(item: membership_type, item_type: 'MembershipType')

      expect(payment_line.item_description).to eq('Adhésion Cirque')
    end

    it 'returns humanized item_type for unknown types' do
      payment_line = described_class.new(item_type: 'UnknownType')

      expect(payment_line.item_description).to eq('Unknowntype')
    end
  end

  describe '#history_description' do
    it 'normalizes a legacy membership upgrade description' do
      membership_type = create(:membership_type, name: 'Adhésion Cirque Tarif Plein')
      membership = build_stubbed(:membership, membership_type: membership_type)
      payment_line = described_class.new(
        item: membership,
        item_type: 'Membership',
        description: "Upgrade d'adhésion de Adhésion Basique vers Adhésion Cirque Tarif Plein (plein tarif)"
      )

      expect(payment_line.history_description).to eq("Passage d'adhésion : Adhésion Basique -> Adhésion Cirque Tarif Plein")
    end

    it 'normalizes duplicated membership prefixes' do
      membership_type = create(:membership_type, name: 'Adhésion Cirque')
      membership = build_stubbed(:membership, membership_type: membership_type)
      payment_line = described_class.new(
        item: membership,
        item_type: 'Membership',
        description: 'Adhésion Adhésion Cirque'
      )

      expect(payment_line.history_description).to eq('Adhésion Cirque')
    end

    it 'renders contribution lines with a cotisation prefix' do
      contribution_formula = build_stubbed(:contribution_formula, duration: 'day')
      contribution = build_stubbed(:contribution, contribution_formula: contribution_formula)
      payment_line = described_class.new(item: contribution, item_type: 'Contribution', description: nil)

      expect(payment_line.history_description).to eq('Cotisation Journée')
    end
  end

  describe '.normalize_membership_name' do
    it 'adds the canonical prefix when the raw name has none' do
      expect(described_class.normalize_membership_name('Cirque Tarif Plein')).to eq('Adhésion Cirque Tarif Plein')
    end

    it 'collapses duplicated legacy prefixes while preserving the canonical spelling' do
      expect(described_class.normalize_membership_name('adhesion adhesion Cirque')).to eq('Adhésion Cirque')
    end

    it 'falls back to a generic label when the raw name is blank' do
      expect(described_class.normalize_membership_name('   ')).to eq('Adhésion')
    end
  end

  describe '#price_euros (from Priceable)' do
    it 'converts cents to euros' do
      payment_line = PaymentLine.new(amount_cents: 1500)
      expect(payment_line.price_euros).to eq(15.0)
    end
  end

  describe '#price_euros= (from Priceable)' do
    it 'converts euros to cents' do
      payment_line = PaymentLine.new
      payment_line.price_euros = 15.50
      expect(payment_line.amount_cents).to eq(1550)
    end
  end

  describe 'class methods' do
    let(:payment) { create(:payment) }

    describe '.create_for_membership!' do
      it 'creates payment line for membership' do
        membership = create(:membership)

        payment_line = PaymentLine.create_for_membership!(payment, membership, 1500)

        expect(payment_line).to be_persisted
        expect(payment_line.payment).to eq(payment)
        expect(payment_line.item).to eq(membership)
        expect(payment_line.item_type).to eq('Membership')
        expect(payment_line.amount_cents).to eq(1500)
        expect(payment_line.description).to eq(PaymentLine.normalize_membership_name(membership.membership_type.name))
      end
    end

    describe '.create_for_contribution_formula!' do
      it 'creates payment line for contribution formula' do
        contribution_formula = create(:contribution_formula, name: 'Plan Trimestriel', duration: 'trimester')

        payment_line = PaymentLine.create_for_contribution_formula!(payment, contribution_formula, 6000)

        expect(payment_line).to be_persisted
        expect(payment_line.payment).to eq(payment)
        expect(payment_line.item).to eq(contribution_formula)
        expect(payment_line.item_type).to eq('ContributionFormula')
        expect(payment_line.amount_cents).to eq(6000)
        expect(payment_line.description).to eq('Plan Trimestriel (trimester)')
      end
    end

    describe '.create_for_membership_type!' do
      it 'creates payment line for membership type' do
        membership_type = create(:membership_type, name: 'Adhésion Cirque')

        payment_line = PaymentLine.create_for_membership_type!(payment, membership_type, 2500)

        expect(payment_line).to be_persisted
        expect(payment_line.payment).to eq(payment)
        expect(payment_line.item).to eq(membership_type)
        expect(payment_line.item_type).to eq('MembershipType')
        expect(payment_line.amount_cents).to eq(2500)
        expect(payment_line.description).to eq('Adhésion Cirque')
      end
    end
  end
end
