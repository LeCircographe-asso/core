# frozen_string_literal: true

require 'rails_helper'

RSpec.describe People::ContributionCreator do
  include ActiveSupport::Testing::TimeHelpers

  let(:person) { create(:person, :with_circus_membership) }
  let(:contribution_formula) { create(:contribution_formula, :pack10) }
  let(:admin_user) { create(:user, :admin, person: create(:person)) }

  describe '#call' do
    context 'with valid attributes' do
      let(:params) do
        {
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id,
          record_attendance: false
        }
      end

      it 'creates a subscription successfully' do
        result = described_class.new(params).call

        expect(result.success?).to be(true)
        expect(result.contribution).to be_present
        expect(result.payment).to be_present
        expect(result.payment.total_cents).to eq(contribution_formula.price_cents)
      end

      it 'fires instrumentation' do
        creator = described_class.new(params)

        expect { creator.call }.to instrument('contribution.created')
      end

      it 'adds an optional donation line to the payment' do
        result = described_class.new(params.merge(donation_cents: 700)).call

        expect(result.success?).to be(true)
        expect(result.payment.total_cents).to eq(contribution_formula.price_cents + 700)
        expect(result.payment.payment_lines.pluck(:item_type, :amount_cents)).to contain_exactly(
          [ "Contribution", contribution_formula.price_cents ],
          [ "Donation", 700 ]
        )
      end
    end

    context 'with record_attendance true' do
      let(:params) do
        {
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id,
          record_attendance: true
        }
      end

      it 'also records the attendance for today, using the purchased contribution' do
        travel_to Date.current.next_occurring(:tuesday).beginning_of_day + 12.hours do
          result = described_class.new(params).call

          expect(result.success?).to be(true)
          expect(result.attendance).to be_present
          expect(result.attendance.person).to eq(person)
          expect(result.attendance.contribution).to eq(result.contribution)
          expect(result.attendance.date).to eq(Date.current)
        end
      end

      it 'still succeeds if the attendance cannot be recorded (e.g. already present today)' do
        travel_to Date.current.next_occurring(:tuesday).beginning_of_day + 12.hours do
          create(:attendance, person: person, date: Date.current, event: nil)

          result = described_class.new(params).call

          expect(result.success?).to be(true)
          expect(result.contribution).to be_present
          expect(result.attendance).to be_nil
        end
      end
    end

    context 'when attendance recording fails (e.g. already checked in today)' do
      let(:params) do
        {
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id,
          record_attendance: true
        }
      end

      it 'still succeeds but reports the attendance failure instead of hiding it' do
        create(:attendance, person: person, date: Date.current, event: nil)

        result = described_class.new(params).call

        expect(result.success?).to be(true)
        expect(result.contribution).to be_present
        expect(result.attendance).to be_nil
        expect(result.attendance_warnings).not_to be_empty
        expect(result.attendance_warnings.first).to include(person.full_name)
      end
    end

    context 'with multiple beneficiaries' do
      let(:other_person) { create(:person, :with_circus_membership) }
      let(:other_formula) { create(:contribution_formula, :day) }

      let(:params) do
        {
          person: person,
          recorded_by_id: admin_user.id,
          payment_method: 'cash',
          beneficiaries: [
            { person: person, contribution_formula_id: contribution_formula.id, record_attendance: false },
            { person: other_person, contribution_formula_id: other_formula.id, record_attendance: false }
          ]
        }
      end

      it 'creates one contribution per beneficiary and a single shared payment' do
        result = described_class.new(params).call

        expect(result.success?).to be(true)
        expect(result.contributions.map(&:person)).to contain_exactly(person, other_person)
        expect(Payment.count).to eq(1)
        expect(result.payment.person).to eq(person)
        expect(result.payment.total_cents).to eq(contribution_formula.price_cents + other_formula.price_cents)
      end

      it 'attributes each payment line to its own beneficiary' do
        result = described_class.new(params).call

        lines = result.payment.payment_lines
        expect(lines.find_by(item_id: result.contributions.first.id).person).to eq(person)
        expect(lines.find_by(item_id: result.contributions.last.id).person).to eq(other_person)
      end

      it 'records attendance per beneficiary when requested' do
        params[:beneficiaries].each { |entry| entry[:record_attendance] = true }

        travel_to Date.current.next_occurring(:tuesday).beginning_of_day + 12.hours do
          result = described_class.new(params).call

          expect(result.attendances.map(&:person)).to contain_exactly(person, other_person)
        end
      end

      it 'keeps the single-beneficiary path unchanged when beneficiaries is absent' do
        result = described_class.new(
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(true)
        expect(result.contributions).to eq([ result.contribution ])
        expect(result.payment.payment_lines.sole.person).to eq(person)
      end
    end

    context 'when the beneficiary already has an active usable contribution' do
      let(:params) do
        {
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        }
      end

      it 'blocks the purchase instead of creating a redundant contribution' do
        described_class.new(params).call # première cotisation, légitime
        contribution_count_before = Contribution.count
        payment_count_before = Payment.count

        described_class.new(params.merge(contribution_formula_id: create(:contribution_formula, :day).id)).call

        expect(Contribution.count).to eq(contribution_count_before)
        expect(Payment.count).to eq(payment_count_before)
      end

      it 'reports a clear failure message' do
        described_class.new(params).call

        result = described_class.new(params.merge(contribution_formula_id: create(:contribution_formula, :day).id)).call

        expect(result.success?).to be(false)
        expect(result.message).to include('a déjà une cotisation active')
      end
    end

    context 'with offered payment' do
      it 'fails when offer_reason missing' do
        result = described_class.new(
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: 'offered',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
      end

      it 'succeeds when super admin provides offer_reason' do
        super_admin = create(:user, :super_admin, person: create(:person))
        result = described_class.new(
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: 'offered',
          recorded_by_id: super_admin.id,
          offer_reason: 'Solidarity'
        ).call

        expect(result.success?).to be(true)
        expect(result.payment.total_cents).to eq(0)
        expect(result.payment.offer_reason).to eq('Solidarity')
      end
    end

    context 'with invalid data' do
      it 'fails when person missing' do
        result = described_class.new(
          contribution_formula_id: contribution_formula.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include(I18n.t('services.validation.invalid_data'))
      end

      it 'fails when plan missing' do
        result = described_class.new(
          person: person,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
      end

      it 'fails when recorded_by missing' do
        result = described_class.new(
          person: person,
          contribution_formula_id: contribution_formula.id,
          payment_method: 'cash'
        ).call

        expect(result.success?).to be(false)
      end
    end

    context 'with non circus membership' do
      let(:basic_person) { create(:person) }
      let!(:basic_membership) { create(:membership, person: basic_person, membership_type: create(:membership_type, category: :basic), status: :active) }

      it 'fails when person cannot buy subscription plans' do
        result = described_class.new(
          person: basic_person,
          contribution_formula_id: contribution_formula.id,
          payment_method: 'cash',
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('adhésion Cirque')
      end
    end
  end
end
