require 'rails_helper'

RSpec.describe MembershipManagement::MembershipDeactivator do
  let(:person) { create(:person) }
  let(:membership_type) { create(:membership_type, category: :circus) }
  let(:admin_user) { create(:user, :admin) }
  let(:membership) { create(:membership, person: person, membership_type: membership_type, status: :active) }

  describe '#call' do
    context 'with valid attributes' do
      let(:params) do
        {
          membership_id: membership.id,
          deactivated_by_id: admin_user.id,
          reason: 'Membership cancelled by user request'
        }
      end

      it 'deactivates the membership successfully' do
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.membership.status).to eq('inactive')
        expect(result.message).to eq('Adhésion désactivée avec succès')
      end

      it 'fires membership.deactivated instrumentation event' do
        expect {
          described_class.new(params).call
        }.to instrument('membership.deactivated')
      end
    end

    context 'with missing attributes' do
      it 'returns failure when reason is missing' do
        service = described_class.new(membership_id: membership.id, deactivated_by_id: admin_user.id)

        result = service.call

        expect(result.success?).to be false
        expect(result.message).to include('Invalid data')
      end
    end

    context 'when record is not found' do
      it 'returns failure when membership does not exist' do
        params = {
          membership_id: 999_999,
          deactivated_by_id: admin_user.id,
          reason: 'Data cleanup'
        }

        result = described_class.new(params).call

        expect(result.success?).to be false
        expect(result.message).to include('not found')
      end
    end

    context 'when user lacks permissions' do
      it 'returns failure for volunteer user' do
        volunteer = create(:user, :volunteer)

        params = {
          membership_id: membership.id,
          deactivated_by_id: volunteer.id,
          reason: 'Volunteer request'
        }

        result = described_class.new(params).call

        expect(result.success?).to be false
        expect(result.message).to include('permissions')
      end
    end
  end
end
