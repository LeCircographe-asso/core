# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttendanceListManagement::AttendanceListUpdater do
  let(:admin_user) { create(:user, :admin) }
  let(:attendance_list) { create(:attendance_list, name: 'Liste initiale', status: :open, list_type: :training) }

  describe '#call' do
    context 'with valid attributes' do
      it 'updates the attendance list and preserves unspecified fields' do
        params = {
          attendance_list_id: attendance_list.id,
          name: 'Nouvelle liste',
          status: 'close',
          updated_by_id: admin_user.id
        }

        result = described_class.new(params).call

        expect(result.success?).to be true
        list = result.attendance_list.reload
        expect(list.name).to eq('Nouvelle liste')
        expect(list.status).to eq('close')
        expect(list.list_type).to eq('training')
      end

      it 'fires attendance_list.updated instrumentation' do
        params = {
          attendance_list_id: attendance_list.id,
          name: 'Instrumented',
          updated_by_id: admin_user.id
        }

        expect do
          described_class.new(params).call
        end.to instrument('attendance_list.updated')
      end
    end

    context 'with invalid attributes' do
      it 'fails when attendance_list_id is missing' do
        result = described_class.new(name: 'Test', updated_by_id: admin_user.id).call

        expect(result.success?).to be false
        expect(result.message).to include('Invalid data')
      end

      it 'fails when attendance list does not exist' do
        result = described_class.new(attendance_list_id: 999_999, updated_by_id: admin_user.id).call

        expect(result.success?).to be false
        expect(result.message).to include('Attendance list or User not found')
      end

      it 'fails when user does not exist' do
        result = described_class.new(attendance_list_id: attendance_list.id, updated_by_id: 999_999).call

        expect(result.success?).to be false
        expect(result.message).to include('Attendance list or User not found')
      end
    end
  end
end
