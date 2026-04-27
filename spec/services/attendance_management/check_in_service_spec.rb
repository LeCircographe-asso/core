require 'rails_helper'

RSpec.describe AttendanceManagement::CheckInService do
  include ActiveSupport::Testing::TimeHelpers

  let(:attendance_list) { create(:attendance_list, status: :open, list_type: :training) }
  let(:person) { create(:person, :with_circus_membership) }
  let(:pack_plan) { create(:contribution_formula, :pack10) }
  let!(:contribution) { create(:contribution, person: person, contribution_formula: pack_plan, sessions_remaining: 5) }

  describe '#call' do
    it 'creates attendance using existing list and contribution' do
      result = described_class.new(person_id: person.id, attendance_list_id: attendance_list.id, contribution_id: contribution.id).call

      expect(result.success?).to be true
      expect(result.attendance.attendance_list).to eq(attendance_list)
      expect(result.attendance.contribution).to eq(contribution)
    end

    it 'auto-selects usable contribution when none provided' do
      result = described_class.new(person_id: person.id, attendance_list_id: attendance_list.id).call

      expect(result.success?).to be true
      expect(result.attendance.contribution).to eq(contribution)
    end

    it 'creates list automatically when missing' do
      # DailyListGenerator refuses Mondays — travel to next Tuesday to ensure list can be created
      travel_to Date.current.next_occurring(:tuesday).beginning_of_day + 12.hours do
        result = described_class.new(person_id: person.id).call

        expect(result.success?).to be true
        expect(result.attendance.attendance_list.list_type).to eq('training')
      end
    end

    it 'returns failure when person not found' do
      result = described_class.new(person_id: 999_999).call

      expect(result.success?).to be false
      expect(result.message).to include('Record not found')
    end
  end
end
