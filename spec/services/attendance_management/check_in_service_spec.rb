# frozen_string_literal: true

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

    it 'returns a clear failure reason when no list exists and none can be created (training closed)' do
      travel_to Date.current.next_occurring(:monday).beginning_of_day + 12.hours do
        result = described_class.new(person_id: person.id).call

        expect(result.success?).to be false
        expect(result.message).to include('closed on Mondays')
      end
    end
  end

  describe 'lending a contribution to someone else' do
    let(:owner) { create(:person, :with_circus_membership) }
    let(:borrowed_pack10) { create(:contribution, person: owner, contribution_formula: pack_plan, sessions_remaining: 4) }

    context 'when the recipient has an active circus membership' do
      let(:recipient) { create(:person, :with_circus_membership) }

      it 'creates the attendance and decrements the lender contribution' do
        result = described_class.new(person_id: recipient.id, attendance_list_id: attendance_list.id, contribution_id: borrowed_pack10.id).call

        expect(result.success?).to be true
        expect(result.attendance.person).to eq(recipient)
        expect(result.attendance.contribution).to eq(borrowed_pack10)
        expect(borrowed_pack10.reload.sessions_remaining).to eq(3)
      end
    end

    context 'when the recipient has no active circus membership' do
      let(:recipient) { create(:person, :with_basic_membership) }

      it 'fails without creating an attendance or decrementing the contribution' do
        expect do
          result = described_class.new(person_id: recipient.id, attendance_list_id: attendance_list.id, contribution_id: borrowed_pack10.id).call
          expect(result.success?).to be false
        end.not_to(change { borrowed_pack10.reload.sessions_remaining })
      end
    end
  end
end
