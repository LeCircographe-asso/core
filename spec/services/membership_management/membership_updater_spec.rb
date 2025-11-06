require 'rails_helper'

RSpec.describe MembershipManagement::MembershipUpdater do
  let(:person) { create(:person) }
  let(:original_type) { create(:membership_type, category: :basic, price_cents: 1500) }
  let(:new_type) { create(:membership_type, category: :circus, price_cents: 2500) }
  let(:admin_user) { create(:user, :admin) }
  let(:membership) do
    create(
      :membership,
      person: person,
      membership_type: original_type,
      started_at: Date.current - 2.months,
      ended_at: Date.current + 10.months,
      status: :active
    )
  end

  describe '#call' do
    context 'with valid attributes' do
      let(:new_start_date) { Date.current - 1.month }
      let(:new_end_date) { Date.current + 1.year }

      let(:params) do
        {
          membership_id: membership.id,
          membership_type_id: new_type.id,
          started_at: new_start_date,
          ended_at: new_end_date,
          updated_by_id: admin_user.id
        }
      end

      it 'updates the membership successfully' do
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.membership.membership_type).to eq(new_type)
        expect(result.membership.started_at).to eq(new_start_date)
        expect(result.membership.ended_at).to eq(new_end_date)
        expect(result.message).to eq('Adhésion mise à jour avec succès')
      end

      it 'fires membership.updated instrumentation event' do
        expect {
          described_class.new(params).call
        }.to instrument('membership.updated')
      end
    end

    context 'with missing attributes' do
      it 'returns failure when membership_id is missing' do
        service = described_class.new(membership_type_id: new_type.id, updated_by_id: admin_user.id)

        result = service.call

        expect(result.success?).to be false
        expect(result.message).to include('Invalid data')
      end
    end

    context 'when record is not found' do
      it "returns failure when membership_type doesn't exist" do
        params = {
          membership_id: membership.id,
          membership_type_id: 999_999,
          updated_by_id: admin_user.id
        }

        result = described_class.new(params).call

        expect(result.success?).to be false
        expect(result.message).to include('not found')
      end
    end

    context 'when validations fail' do
      it 'returns failure when ended_at is before started_at' do
        params = {
          membership_id: membership.id,
          membership_type_id: new_type.id,
          started_at: Date.current,
          ended_at: Date.current,
          updated_by_id: admin_user.id
        }

        result = described_class.new(params).call

        expect(result.success?).to be false
        expect(result.message).to include('Validation error')
      end
    end

    context 'when user lacks permissions' do
      it 'returns failure for volunteer user' do
        volunteer = create(:user, :volunteer)

        params = {
          membership_id: membership.id,
          membership_type_id: new_type.id,
          updated_by_id: volunteer.id
        }

        result = described_class.new(params).call

        expect(result.success?).to be false
        expect(result.message).to include('permissions')
      end
    end
  end
end

