require 'rails_helper'

RSpec.describe MemberNumberManagement::MemberNumberChanger do
  let(:person) { create(:person) }
  let(:admin_user) { create(:user, :admin) }
  let(:volunteer) { create(:user, :volunteer) }
  let(:generated_number) { format("%02dC400", Date.current.year % 100) }
  let(:manual_number) { format("%02dC900", Date.current.year % 100) }

  before do
    MemberManagementService.assign_member_number(person, 'BASIQUE')
  end

  describe '#call' do
    context 'with valid attributes' do
      let(:params) do
        {
          person_id: person.id,
          new_member_number: manual_number,
          new_membership_type: 'CIRQUE',
          change_notes: 'Migration vers la troupe cirque',
          changed_by_id: admin_user.id
        }
      end

      before do
        allow(MemberManagementService).to receive(:generate_member_number).and_call_original
        allow(MemberManagementService).to receive(:generate_member_number).with('CIRQUE').and_return(generated_number)
      end

      it 'changes the member number and updates history' do
        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.old_number).to be_present
        expect(result.new_number).to eq(manual_number)
        expect(person.reload.member_number).to eq(manual_number)

        current_history = person.member_number_histories.current.first
        expect(current_history.member_number).to eq(manual_number)
        expect(current_history.notes).to include('Migration vers la troupe cirque')
      end

      it 'fires member_number.changed instrumentation' do
        expect {
          described_class.new(params).call
        }.to instrument('member_number.changed')
      end
    end

    context 'with invalid attributes' do
      it 'fails when format is invalid' do
        result = described_class.new(
          person_id: person.id,
          new_member_number: 'INVALID',
          new_membership_type: 'CIRQUE',
          changed_by_id: admin_user.id
        ).call

        expect(result.success?).to be false
        expect(result.message).to include('Format invalide')
      end

      it 'fails when new number is already taken' do
        existing_person = create(:person)
        existing_number = MemberManagementService.assign_member_number(existing_person, 'CIRQUE')

        result = described_class.new(
          person_id: person.id,
          new_member_number: existing_number,
          new_membership_type: 'CIRQUE',
          changed_by_id: admin_user.id
        ).call

        expect(result.success?).to be false
        expect(result.message).to include('déjà utilisé')
      end
    end

    context 'with permission checks' do
      it 'rejects volunteers' do
        result = described_class.new(
          person_id: person.id,
          new_member_number: manual_number,
          new_membership_type: 'CIRQUE',
          changed_by_id: volunteer.id
        ).call

        expect(result.success?).to be false
        expect(result.message).to include('Insufficient permissions')
      end
    end

    context 'with missing records' do
      it 'fails when person does not exist' do
        result = described_class.new(
          person_id: 999_999,
          new_member_number: manual_number,
          new_membership_type: 'CIRQUE',
          changed_by_id: admin_user.id
        ).call

        expect(result.success?).to be false
        expect(result.message).to include('not found')
      end

      it 'fails when user does not exist' do
        result = described_class.new(
          person_id: person.id,
          new_member_number: manual_number,
          new_membership_type: 'CIRQUE',
          changed_by_id: 999_999
        ).call

        expect(result.success?).to be false
        expect(result.message).to include('not found')
      end
    end
  end
end

