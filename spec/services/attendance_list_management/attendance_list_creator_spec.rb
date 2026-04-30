# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttendanceListManagement::AttendanceListCreator do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin_user) { create(:user, :admin) }

  describe '#call' do
    context 'with valid attributes' do
      let(:params) do
        {
          name: 'Cours du mercredi',
          status: 'open',
          list_type: 'training',
          start_date: Time.zone.parse('2025-03-12 18:00'),
          created_by_id: admin_user.id
        }
      end

      it 'creates the attendance list and sets end_date to end of day' do
        result = described_class.new(params).call

        expect(result.success?).to be true
        list = result.attendance_list
        expect(list).to be_persisted
        expect(list.start_date).to eq(params[:start_date])
        expect(list.end_date).to eq(params[:start_date].change(hour: 23, min: 59, sec: 59))
        expect(list.status).to eq('open')
      end

      it 'fires attendance_list.created instrumentation' do
        expect do
          described_class.new(params).call
        end.to instrument('attendance_list.created')
      end
    end

    context 'with invalid attributes' do
      it 'fails when name is missing' do
        result = described_class.new(start_date: Time.current, created_by_id: admin_user.id).call

        expect(result.success?).to be false
        expect(result.message).to include(I18n.t('services.validation.invalid_data'))
      end

      it 'fails when created_by user does not exist' do
        result = described_class.new(name: 'Test', start_date: Time.current, created_by_id: 999_999).call

        expect(result.success?).to be false
        expect(result.message).to include('User not found')
      end
    end
  end
end
