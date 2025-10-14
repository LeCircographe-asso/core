require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:started_at) }
    it { should validate_presence_of(:ended_at) }
    it { should validate_presence_of(:status) }
  end

  describe 'associations' do
    it { should belong_to(:person) }
    it { should belong_to(:membership_type) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(inactive: 0, active: 1, expired: 2) }
  end

  describe '#expired?' do
    it 'returns true when ended_at is in the past' do
      membership = build(:membership, ended_at: 1.day.ago)
      expect(membership.expired?).to be true
    end

    it 'returns false when ended_at is in the future' do
      membership = build(:membership, ended_at: 1.day.from_now)
      expect(membership.expired?).to be false
    end
  end

  describe '#can_upgrade_to?' do
    let(:person) { create(:person) }
    let(:basic_type) { create(:membership_type, category: :basic) }
    let(:circus_full_type) { create(:membership_type, category: :circus_full) }
    let(:circus_reduced_type) { create(:membership_type, category: :circus_reduced) }
    let(:basic_membership) { create(:membership, person: person, membership_type: basic_type) }
    let(:circus_membership) { create(:membership, person: person, membership_type: circus_full_type) }

    it 'allows basic to upgrade to circus' do
      expect(basic_membership.can_upgrade_to?(circus_full_type)).to be true
    end

    it 'allows circus to change to another circus type' do
      expect(circus_membership.can_upgrade_to?(circus_reduced_type)).to be true
    end

    it 'does not allow circus to downgrade to basic' do
      expect(circus_membership.can_upgrade_to?(basic_type)).to be false
    end

    it 'does not allow upgrade to same type' do
      expect(basic_membership.can_upgrade_to?(basic_type)).to be false
    end
  end

  describe '#basic?' do
    let(:basic_type) { create(:membership_type, category: :basic) }
    let(:circus_type) { create(:membership_type, category: :circus_full) }

    it 'returns true for basic membership' do
      membership = build(:membership, membership_type: basic_type)
      expect(membership.basic?).to be true
    end

    it 'returns false for circus membership' do
      membership = build(:membership, membership_type: circus_type)
      expect(membership.basic?).to be false
    end
  end

  describe '#circus?' do
    let(:basic_type) { create(:membership_type, category: :basic) }
    let(:circus_type) { create(:membership_type, category: :circus_full) }

    it 'returns true for circus membership' do
      membership = build(:membership, membership_type: circus_type)
      expect(membership.circus?).to be true
    end

    it 'returns false for basic membership' do
      membership = build(:membership, membership_type: basic_type)
      expect(membership.circus?).to be false
    end
  end

  describe '#upgrade_to!' do
    let(:person) { create(:person) }
    let(:basic_type) { create(:membership_type, category: :basic) }
    let(:circus_type) { create(:membership_type, category: :circus_full) }
    let(:basic_membership) { create(:membership, person: person, membership_type: basic_type, status: :active) }

    it 'creates a new membership and deactivates the old one' do
      expect { basic_membership.upgrade_to!(circus_type) }.to change(Membership, :count).by(1)
      
      basic_membership.reload
      expect(basic_membership.status).to eq('inactive')
      
      new_membership = person.current_membership
      expect(new_membership.membership_type).to eq(circus_type)
      expect(new_membership.status).to eq('active')
    end

    it 'preserves the first_joined_at date' do
      first_joined = 1.year.ago.to_date
      basic_membership.update!(first_joined_at: first_joined)
      
      new_membership = basic_membership.upgrade_to!(circus_type)
      expect(new_membership.first_joined_at).to eq(first_joined)
    end

    it 'raises error for invalid upgrade' do
      circus_membership = create(:membership, person: person, membership_type: circus_type, status: :active)
      
      expect { circus_membership.upgrade_to!(basic_type) }.to raise_error(/Cannot upgrade/)
    end
  end

  describe 'scopes' do
    let(:person) { create(:person) }
    let(:membership_type) { create(:membership_type) }
    let!(:active_membership) { create(:membership, person: person, membership_type: membership_type, status: :active) }
    let!(:inactive_membership) { create(:membership, person: person, membership_type: membership_type, status: :inactive) }
    let!(:expired_membership) { create(:membership, person: person, membership_type: membership_type, status: :expired) }

    describe '.active' do
      it 'returns only active memberships' do
        expect(Membership.active).to include(active_membership)
        expect(Membership.active).not_to include(inactive_membership, expired_membership)
      end
    end

    describe '.current' do
      it 'returns memberships that are currently valid' do
        current_membership = create(:membership, 
          person: person, 
          membership_type: membership_type,
          started_at: 1.month.ago,
          ended_at: 1.month.from_now
        )
        
        expect(Membership.current).to include(current_membership)
      end
    end
  end

  describe 'custom validations' do
    let(:person) { create(:person) }
    let(:membership_type) { create(:membership_type) }

    it 'validates end_date is after start_date' do
      membership = build(:membership, 
        person: person, 
        membership_type: membership_type,
        started_at: Date.current,
        ended_at: 1.day.ago
      )
      
      expect(membership).not_to be_valid
      expect(membership.errors[:ended_at]).to include('must be after start date')
    end

    it 'validates no overlapping active memberships' do
      create(:membership, 
        person: person, 
        membership_type: membership_type,
        started_at: 1.month.ago,
        ended_at: 1.month.from_now,
        status: :active
      )
      
      overlapping_membership = build(:membership, 
        person: person, 
        membership_type: membership_type,
        started_at: Date.current,
        ended_at: 2.months.from_now,
        status: :active
      )
      
      expect(overlapping_membership).not_to be_valid
      expect(overlapping_membership.errors[:base]).to include('Person already has an active membership during this period')
    end
  end
end
