require 'rails_helper'

RSpec.describe AttendanceManagement::CheckInService do
  let(:attendance_list) { create(:attendance_list, status: :open, list_type: :training) }
  let(:person) { create(:person, :with_circus_membership) }
  let(:pack_plan) { create(:subscription_plan, :pack10) }
  let!(:book_of_entry) { create(:book_of_entry, person: person, subscription_plan: pack_plan, sessions_remaining: 5) }

  describe '#call' do
    it 'creates attendance using existing list and book_of_entry' do
      result = described_class.new(person_id: person.id, attendance_list_id: attendance_list.id, book_of_entry_id: book_of_entry.id).call

      expect(result.success?).to be true
      expect(result.attendance.attendance_list).to eq(attendance_list)
      expect(result.attendance.book_of_entry).to eq(book_of_entry)
    end

    it 'auto-selects usable book_of_entry when none provided' do
      result = described_class.new(person_id: person.id, attendance_list_id: attendance_list.id).call

      expect(result.success?).to be true
      expect(result.attendance.book_of_entry).to eq(book_of_entry)
    end

    it 'creates list automatically when missing' do
      result = described_class.new(person_id: person.id).call

      expect(result.success?).to be true
      expect(result.attendance.attendance_list.list_type).to eq('training')
    end

    it 'returns failure when person not found' do
      result = described_class.new(person_id: 999_999).call

      expect(result.success?).to be false
      expect(result.message).to include('Record not found')
    end
  end
end

