require 'rails_helper'

RSpec.describe AttendanceManagement::AttendanceRemover do
  let(:attendance_list) { create(:attendance_list) }
  let(:admin_user) { create(:user, :admin) }

  describe '#call' do
    context 'with pack10 book of entry' do
      let(:person) { create(:person, :with_circus_membership) }
      let(:pack_plan) { create(:contribution_formula, :pack10) }
      let!(:contribution) { create(:contribution, person: person, contribution_formula: pack_plan, sessions_remaining: 4) }
      let!(:attendance) do
        create(:attendance, person: person, attendance_list: attendance_list, contribution: contribution, date: Date.current)
      end

      it 'removes attendance and refunds a session' do
        initial_after_creation = contribution.reload.sessions_remaining
        remover = described_class.new(attendance_id: attendance.id, deleted_by_id: admin_user.id)
        expect {
          result = remover.call
          expect(result.success?).to be true
        }.to change(Attendance, :count).by(-1)

        expect(contribution.reload.sessions_remaining).to eq(initial_after_creation + 1)
        expect(contribution.status).to eq('active')
      end
    end

    context 'with day pass' do
      let(:person) { create(:person, :with_circus_membership) }
      let(:day_plan) { create(:contribution_formula, :day) }
      let!(:contribution) do
        create(:contribution, person: person, contribution_formula: day_plan, sessions_remaining: 0, status: :consumed, expires_at: Date.current.end_of_day)
      end
      let!(:attendance) { create(:attendance, person: person, attendance_list: attendance_list, contribution: contribution) }

      it 'reactivates the day pass on refund' do
        described_class.new(attendance_id: attendance.id).call

        expect(contribution.reload.sessions_remaining).to eq(1)
        expect(contribution.status).to eq('active')
      end
    end

    context 'with annual subscription' do
      let(:person) { create(:person, :with_circus_membership) }
      let(:annual_plan) { create(:contribution_formula, :annual) }
      let!(:contribution) do
        create(:contribution, person: person, contribution_formula: annual_plan, sessions_remaining: nil, expires_at: 1.year.from_now)
      end
      let!(:attendance) { create(:attendance, person: person, attendance_list: attendance_list, contribution: contribution) }

      it 'removes attendance without altering unlimited plan' do
        described_class.new(attendance_id: attendance.id).call

        expect(contribution.reload.sessions_remaining).to be_nil
        expect(contribution.status).to eq('active')
      end
    end

    context 'when attendance not found' do
      it 'returns failure' do
        result = described_class.new(attendance_id: 999_999).call

        expect(result.success?).to be false
        expect(result.message).to include('Attendance not found')
      end
    end
  end
end
