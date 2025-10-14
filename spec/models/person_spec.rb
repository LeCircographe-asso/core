require 'rails_helper'

RSpec.describe Person, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }

    it 'validates email uniqueness when present' do
      create(:person, email: 'test@example.com')
      person = build(:person, email: 'test@example.com')
      expect(person).not_to be_valid
    end

    it 'validates phone uniqueness when present' do
      create(:person, phone: '+33123456789')
      person = build(:person, phone: '+33123456789')
      expect(person).not_to be_valid
    end
  end

  describe 'associations' do
    it { should have_one(:user).dependent(:nullify) }
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:payments).dependent(:destroy) }
    it { should have_many(:attendances).dependent(:destroy) }
  end

  describe '#full_name' do
    it 'returns the full name' do
      person = build(:person, first_name: 'John', last_name: 'Doe')
      expect(person.full_name).to eq('John Doe')
    end
  end

  describe '#has_user_account?' do
    it 'returns true when person has a user account' do
      person = create(:person)
      create(:user, person: person)
      expect(person.has_user_account?).to be true
    end

    it 'returns false when person has no user account' do
      person = create(:person)
      expect(person.has_user_account?).to be false
    end
  end

  describe '#current_membership' do
    it 'returns the current active membership' do
      person = create(:person)
      membership_type = create(:membership_type)
      membership = create(:membership, person: person, membership_type: membership_type, status: :active)

      expect(person.current_membership).to eq(membership)
    end

    it 'returns nil when no active membership' do
      person = create(:person)
      expect(person.current_membership).to be_nil
    end
  end

  describe '#has_active_membership?' do
    it 'returns true when person has an active membership' do
      person = create(:person)
      membership_type = create(:membership_type)
      create(:membership, person: person, membership_type: membership_type, status: :active)

      expect(person.has_active_membership?).to be true
    end

    it 'returns false when person has no active membership' do
      person = create(:person)
      expect(person.has_active_membership?).to be false
    end
  end

  describe 'scopes' do
    let!(:person_with_user) { create(:person) }
    let!(:person_without_user) { create(:person) }
    let!(:user) { create(:user, person: person_with_user) }

    describe '.with_user_account' do
      it 'returns only people with user accounts' do
        expect(Person.with_user_account).to include(person_with_user)
        expect(Person.with_user_account).not_to include(person_without_user)
      end
    end

    describe '.without_user_account' do
      it 'returns only people without user accounts' do
        expect(Person.without_user_account).to include(person_without_user)
        expect(Person.without_user_account).not_to include(person_with_user)
      end
    end

    describe '.by_name' do
      let!(:john_doe) { create(:person, first_name: 'John', last_name: 'Doe') }
      let!(:jane_smith) { create(:person, first_name: 'Jane', last_name: 'Smith') }

      it 'finds people by first name' do
        expect(Person.by_name('John')).to include(john_doe)
      end

      it 'finds people by last name' do
        expect(Person.by_name('Doe')).to include(john_doe)
      end

      it 'finds people by partial name' do
        expect(Person.by_name('John')).to include(john_doe)
        expect(Person.by_name('Doe')).to include(john_doe)
      end
    end
  end
end
