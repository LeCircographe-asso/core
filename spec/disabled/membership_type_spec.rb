require 'rails_helper'

RSpec.describe MembershipType, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it 'validates name uniqueness' do
      create(:membership_type, name: 'Test Type')
      membership_type = build(:membership_type, name: 'Test Type')
      expect(membership_type).not_to be_valid
    end
    it { should validate_presence_of(:category) }
    it { should validate_presence_of(:price_cents) }
    it { should validate_numericality_of(:price_cents).is_greater_than(0) }
  end

  describe 'associations' do
    it { should have_many(:memberships).dependent(:restrict_with_error) }
    it { should have_many(:subscription_plans).dependent(:destroy) }
  end

  describe 'enums' do
    it { should define_enum_for(:category).with_values(basic: 0, circus_full: 1, circus_reduced: 2) }
  end

  describe '#circus?' do
    it 'returns true for circus_full' do
      membership_type = build(:membership_type, category: :circus_full)
      expect(membership_type.circus?).to be true
    end

    it 'returns true for circus_reduced' do
      membership_type = build(:membership_type, category: :circus_reduced)
      expect(membership_type.circus?).to be true
    end

    it 'returns false for basic' do
      membership_type = build(:membership_type, category: :basic)
      expect(membership_type.circus?).to be false
    end
  end

  describe '#basic?' do
    it 'returns true for basic category' do
      membership_type = build(:membership_type, category: :basic)
      expect(membership_type.basic?).to be true
    end

    it 'returns false for circus categories' do
      membership_type = build(:membership_type, category: :circus_full)
      expect(membership_type.basic?).to be false
    end
  end

  describe '#price_euros' do
    it 'converts cents to euros' do
      membership_type = build(:membership_type, price_cents: 2500)
      expect(membership_type.price_euros).to eq(25.0)
    end
  end

  describe '#price_euros=' do
    it 'converts euros to cents' do
      membership_type = build(:membership_type)
      membership_type.price_euros = 25.0
      expect(membership_type.price_cents).to eq(2500)
    end
  end

  describe 'scopes' do
    let!(:basic_type) { create(:membership_type, category: :basic) }
    let!(:circus_full_type) { create(:membership_type, category: :circus_full) }
    let!(:circus_reduced_type) { create(:membership_type, category: :circus_reduced) }

    describe '.circus_types' do
      it 'returns only circus membership types' do
        expect(MembershipType.circus_types).to include(circus_full_type, circus_reduced_type)
        expect(MembershipType.circus_types).not_to include(basic_type)
      end
    end

    describe '.basic_types' do
      it 'returns only basic membership types' do
        expect(MembershipType.basic_types).to include(basic_type)
        expect(MembershipType.basic_types).not_to include(circus_full_type, circus_reduced_type)
      end
    end
  end

  describe '.create_default_types!' do
    it 'creates default membership types' do
      expect { MembershipType.create_default_types! }.to change(MembershipType, :count).by(3)
      
      expect(MembershipType.find_by(name: 'Adhésion Basique')).to be_present
      expect(MembershipType.find_by(name: 'Adhésion Cirque Complète')).to be_present
      expect(MembershipType.find_by(name: 'Adhésion Cirque Réduite')).to be_present
    end

    it 'does not create duplicates' do
      MembershipType.create_default_types!
      expect { MembershipType.create_default_types! }.not_to change(MembershipType, :count)
    end
  end
end
