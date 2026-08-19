# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttendanceListManagement::DailyListGenerator do
  include ActiveSupport::Testing::TimeHelpers

  describe '#call' do
    context 'on any day of the week' do
      it 'creates a training attendance list for the given day' do
        travel_to(Date.parse('2025-02-04')) do # Tuesday
          result = described_class.new.call

          expect(result.success?).to be true
          list = result.attendance_list
          expect(list).to be_persisted
          expect(list.list_type).to eq('training')
          expect(list.status).to eq('open')
          expect(list.start_date.hour).to eq(18)
          expect(list.start_date.to_date).to eq(Date.current)
        end
      end

      it 'fires attendance_list.daily_created instrumentation' do
        travel_to(Date.parse('2025-02-05')) do
          expect do
            described_class.new(created_by_id: 42).call
          end.to instrument('attendance_list.daily_created')
        end
      end

      it 'creates a training attendance list on Monday too (exceptional/off-schedule openings must not be blocked)' do
        travel_to(Date.parse('2025-02-03')) do # Monday
          result = described_class.new.call

          expect(result.success?).to be true
          expect(result.attendance_list).to be_persisted
        end
      end
    end

    context 'when list already exists' do
      it 'prevents duplicate creation for the same day' do
        travel_to(Date.parse('2025-02-06')) do
          first_call = described_class.new.call
          expect(first_call.success?).to be true

          duplicate_call = described_class.new.call
          expect(duplicate_call.success?).to be false
          expect(duplicate_call.message).to include('already exists')
        end
      end
    end

    context 'with custom date' do
      it 'uses the provided date for generation' do
        target_date = Date.parse('2025-02-07')
        result = described_class.new(date: target_date).call

        expect(result.success?).to be true
        expect(result.attendance_list.start_date.to_date).to eq(target_date)
      end
    end
  end
end
