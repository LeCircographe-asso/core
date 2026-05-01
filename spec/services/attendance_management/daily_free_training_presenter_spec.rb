# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttendanceManagement::DailyFreeTrainingPresenter do
  let(:date) { Date.parse('2025-02-05') }
  let(:training_list) { create(:attendance_list, list_type: :training, start_date: date.beginning_of_day + 18.hours, end_date: date.end_of_day) }
  let(:pack10_plan) { create(:contribution_formula, :pack10) }
  let(:day_plan) { create(:contribution_formula, :day) }

  describe '#call' do
    context 'when list exists' do
      let!(:pack_attendance) do
        person = create(:person, :with_circus_membership)
        book = create(:contribution, person: person, contribution_formula: pack10_plan, sessions_remaining: 4)
        create(:attendance, person: person, attendance_list: training_list, contribution: book, date: date)
      end

      let!(:day_attendance) do
        person = create(:person, :with_circus_membership)
        book = create(:contribution, person: person, contribution_formula: day_plan, sessions_remaining: 0, status: :consumed, purchased_at: date, expires_at: date.end_of_day)
        create(:attendance, person: person, attendance_list: training_list, contribution: book, date: date)
      end

      it 'returns attendance metrics for the training day' do
        result = described_class.new(date: date).call

        expect(result.success?).to be true
        expect(result.attendance_list).to eq(training_list)
        expect(result.total_attendances).to eq(2)
        expect(result.pack10_sessions).to eq(1)
        expect(result.day_passes).to eq(1)
      end
    end

    context 'when list is missing' do
      it 'returns failure' do
        result = described_class.new(date: date).call

        expect(result.success?).to be false
        expect(result.message).to include('No training list')
      end
    end
  end
end
