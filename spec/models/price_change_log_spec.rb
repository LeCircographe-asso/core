# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PriceChangeLog, type: :model do
  let(:membership_type) { create(:membership_type) }
  let(:user) { create(:user, :admin) }

  describe 'associations' do
    it { should belong_to(:loggable) }
    it { should belong_to(:user).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:action) }
  end

  describe '.log' do
    it 'creates a log entry with loggable, user, and action' do
      log = PriceChangeLog.log(membership_type, user, 'merged')
      expect(log.loggable).to eq(membership_type)
      expect(log.user).to eq(user)
      expect(log.action).to eq('merged')
    end

    it 'accepts an optional change_data hash and serializes it as JSON' do
      log = PriceChangeLog.log(membership_type, user, 'versioned', old_price_cents: 1000, new_price_cents: 1500)
      parsed = JSON.parse(log.change_data)
      expect(parsed['old_price_cents']).to eq(1000)
      expect(parsed['new_price_cents']).to eq(1500)
    end

    it 'can create a log without a user' do
      log = PriceChangeLog.log(membership_type, nil, 'archived')
      expect(log.user).to be_nil
      expect(log.action).to eq('archived')
    end

    it 'works with either MembershipType or ContributionFormula as loggable' do
      formula = create(:contribution_formula)
      log = PriceChangeLog.log(formula, user, 'merged')
      expect(log.loggable).to eq(formula)
    end
  end
end
