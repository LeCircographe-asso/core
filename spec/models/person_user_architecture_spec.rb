# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Person-User Architecture', type: :model do
  describe 'Person delegation to User' do
    it 'delegates personal attributes to Person' do
      person = create(:person, first_name: 'John', last_name: 'Doe', email: 'john@example.com')
      user = create(:user, person: person, email_address: 'john@example.com')

      # Test delegation
      expect(user.first_name).to eq('John')
      expect(user.last_name).to eq('Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe 'Relations through Person' do
    it 'can access memberships through person' do
      person = create(:person)
      user = create(:user, person: person)
      membership_type = create(:membership_type)
      membership = create(:membership, person: person, membership_type: membership_type)

      expect(user.memberships).to include(membership)
    end

    it 'can access empty payments collection through person' do
      person = create(:person)
      user = create(:user, person: person)

      # Just test that the association exists and is empty
      expect(user.payments).to be_empty
    end
  end

  describe 'User-Person invariant' do
    it 'auto-creates a minimal person when missing on create' do
      user = create(:user, person: nil, email_address: 'orphan@example.com')

      expect(user.person).to be_present
      expect(user.person.first_name).to eq('Web')
      expect(user.person.last_name).to eq('User')
      expect(user.person.email).to eq('orphan@example.com')
    end
  end
end
