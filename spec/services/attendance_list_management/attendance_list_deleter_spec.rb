# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttendanceListManagement::AttendanceListDeleter do
  let(:admin_user) { create(:user, :admin) }
  let!(:attendance_list) { create(:attendance_list) }

  describe '#call' do
    context 'with valid attributes' do
      it 'destroys the attendance list and returns success' do
        params = { attendance_list_id: attendance_list.id, deleted_by_id: admin_user.id }

        expect do
          result = described_class.new(params).call
          expect(result.success?).to be true
        end.to change(AttendanceList, :count).by(-1)
      end

      it 'fires attendance_list.deleted instrumentation' do
        params = { attendance_list_id: attendance_list.id, deleted_by_id: admin_user.id }

        expect do
          described_class.new(params).call
        end.to instrument('attendance_list.deleted')
      end
    end

    context 'with invalid attributes' do
      it 'fails when attendance_list_id is missing' do
        result = described_class.new(deleted_by_id: admin_user.id).call

        expect(result.success?).to be false
        expect(result.message).to include('Invalid data')
      end

      it 'fails when attendance list does not exist' do
        result = described_class.new(attendance_list_id: 999_999, deleted_by_id: admin_user.id).call

        expect(result.success?).to be false
        expect(result.message).to include('Attendance list or User not found')
      end

      it 'fails when user does not exist' do
        result = described_class.new(attendance_list_id: attendance_list.id, deleted_by_id: 999_999).call

        expect(result.success?).to be false
        expect(result.message).to include('Attendance list or User not found')
      end
    end
  end
end
