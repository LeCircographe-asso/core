# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MemberNumberManagement::MemberNumberSuggester do
  describe '#call' do
    context 'when generation succeeds' do
      it 'returns a suggested number for the requested membership type' do
        suggested = format('%02dC123', Date.current.year % 100)
        expect(MemberManagementService).to receive(:generate_member_number).with('CIRQUE').and_return(suggested)

        result = described_class.new(membership_type: 'CIRQUE').call

        expect(result.success?).to be true
        expect(result.suggested_number).to eq(suggested)
        expect(result.membership_type).to eq('CIRQUE')
      end
    end

    context 'when generation fails' do
      it 'returns a failure result with the error message' do
        allow(MemberManagementService).to receive(:generate_member_number).and_raise(StandardError, 'boom')

        result = described_class.new.call

        expect(result.success?).to be false
        expect(result.message).to include('Error generating member number: boom')
      end
    end
  end
end
