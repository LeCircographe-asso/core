# frozen_string_literal: true

require 'rails_helper'

RSpec.describe People::OfferPolicy do
  let(:person) { create(:person) }

  describe '.validate!' do
    it 'raises for a volunteer, regardless of offer_type' do
      volunteer = create(:user, :volunteer)

      expect do
        described_class.validate!(
          recorded_by: volunteer,
          person: person,
          offer_type: 'contribution',
          offer_reason: 'Bénévolat'
        )
      end.to raise_error(/admins et super-admins/)
    end

    it 'raises when no reason is given, even for an admin' do
      admin = create(:user, :admin)

      expect do
        described_class.validate!(
          recorded_by: admin,
          person: person,
          offer_type: 'membership',
          offer_reason: ''
        )
      end.to raise_error(/raison/)
    end

    it 'succeeds for an admin with a reason' do
      admin = create(:user, :admin)

      expect(
        described_class.validate!(
          recorded_by: admin,
          person: person,
          offer_type: 'membership',
          offer_reason: 'Geste commercial'
        )
      ).to be(true)
    end
  end
end
