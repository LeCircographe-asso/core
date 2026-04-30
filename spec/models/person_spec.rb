# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Person, type: :model do
  describe 'validations' do
    it 'can be created' do
      person = Person.new(first_name: 'John', last_name: 'Doe')
      expect(person).to be_present
    end

    it 'requires first_name' do
      person = Person.new(last_name: 'Doe')
      expect(person).not_to be_valid
      expect(person.errors[:first_name]).to include(I18n.t('errors.messages.blank'))
    end

    it 'requires last_name' do
      person = Person.new(first_name: 'John')
      expect(person).not_to be_valid
      expect(person.errors[:last_name]).to include(I18n.t('errors.messages.blank'))
    end

    it 'allows blank email even if newsletter_subscribed is true' do
      person = build(:person, email: nil, newsletter_subscribed: true)

      expect(person).to be_valid
    end

    it 'allows blank email when newsletter_subscribed is false' do
      person = build(:person, email: nil, newsletter_subscribed: false)

      expect(person).to be_valid
    end

    it 'validates email uniqueness' do
      create(:person, email: 'test@example.com')
      person = Person.new(first_name: 'John', last_name: 'Doe', email: 'test@example.com')
      expect(person).not_to be_valid
      expect(person.errors[:email]).to include(I18n.t('errors.messages.taken'))
    end

    it 'validates phone uniqueness' do
      create(:person, phone: '0123456789')
      person = Person.new(first_name: 'John', last_name: 'Doe', phone: '0123456789')
      expect(person).not_to be_valid
      expect(person.errors[:phone]).to include(I18n.t('errors.messages.taken'))
    end

    it 'validates member_number uniqueness' do
      create(:person, member_number: '25U001')
      person = Person.new(first_name: 'John', last_name: 'Doe', member_number: '25U001')
      expect(person).not_to be_valid
      expect(person.errors[:member_number]).to include(I18n.t('errors.messages.taken'))
    end

    # DEPRECATED: Person can exist without membership (newsletter subscribers, prospects, etc.)
    # The validation must_have_active_membership is not currently activated in the model
    # it "must have active membership unless skip_membership_validation is true" do
    #   person = create(:person, :without_membership)
    #   person.skip_membership_validation = false
    #
    #   expect(person).not_to be_valid
    #   expect(person.errors[:base]).to include("Une adhésion active est obligatoire")
    # end

    it 'allows no active membership if skip_membership_validation is true' do
      person = create(:person)
      person.skip_membership_validation = true
      person.memberships.destroy_all

      expect(person).to be_valid
    end
  end

  describe 'associations' do
    it 'can have a user account' do
      person = create(:person)
      user = create(:user, person: person)
      expect(person.user).to eq(user)
    end

    it 'can have multiple memberships' do
      person = create(:person)
      membership1 = create(:membership, person: person, started_at: 1.year.ago, ended_at: 6.months.ago, status: :inactive)
      membership2 = create(:membership, person: person, started_at: 3.months.ago, ended_at: 9.months.from_now, status: :active)

      expect(person.memberships).to include(membership1, membership2)
    end

    it 'can have multiple payments' do
      person = create(:person)
      payment1 = create(:payment, person: person)
      payment2 = create(:payment, person: person)

      expect(person.payments).to include(payment1, payment2)
    end

    it 'can have book of entries' do
      person = create(:person)
      contribution = create(:contribution, person: person)

      expect(person.contributions).to include(contribution)
    end

    it 'can have member number histories' do
      person = create(:person, member_number: '25U001')
      history = create(:member_number_history, person: person, member_number: '25U001')

      expect(person.member_number_histories).to include(history)
    end
  end

  describe 'scopes' do
    let!(:person_with_user) { create(:person, :with_user) }
    let!(:person_without_user) { create(:person) }
    let!(:person_with_active_membership) { create(:person, :with_active_membership) }
    let!(:person_with_expiring_membership) { create(:person, :with_expiring_membership) }
    let!(:person_with_expired_membership) { create(:person, :with_expired_membership) }
    let!(:person_without_membership) { create(:person, :without_membership) }

    it 'finds people with user accounts' do
      expect(Person.with_user_account).to include(person_with_user)
      expect(Person.with_user_account).not_to include(person_without_user)
    end

    it 'finds people without user accounts' do
      expect(Person.without_user_account).to include(person_without_user)
      expect(Person.without_user_account).not_to include(person_with_user)
    end

    it 'finds people with active memberships' do
      expect(Person.with_active_membership).to include(person_with_active_membership)
      expect(Person.with_active_membership).not_to include(person_without_membership)
    end

    it 'finds people with expiring memberships' do
      expect(Person.with_expiring_membership).to include(person_with_expiring_membership)
    end

    it 'finds people with expired memberships' do
      expect(Person.with_expired_membership).to include(person_with_expired_membership)
    end

    it 'finds people without memberships' do
      expect(Person.without_membership).to include(person_without_membership)
    end

    it 'searches by contact information' do
      person = create(:person, first_name: 'John', last_name: 'Doe', email: 'john@example.com')

      expect(Person.search_by_contact('John')).to include(person)
      expect(Person.search_by_contact('Doe')).to include(person)
      expect(Person.search_by_contact('john@example.com')).to include(person)
    end

    it 'filters by name' do
      person = create(:person, first_name: 'John', last_name: 'Doe')

      expect(Person.by_name('John')).to include(person)
      expect(Person.by_name('Doe')).to include(person)
    end

    it 'filters adults and minors' do
      adult = create(:person, is_minor: false)
      minor = create(:person, is_minor: true)

      expect(Person.adults).to include(adult)
      expect(Person.adults).not_to include(minor)
      expect(Person.minors).to include(minor)
      expect(Person.minors).not_to include(adult)
    end
  end

  describe '#full_name' do
    it 'returns first_name and last_name combined' do
      person = Person.new(first_name: 'John', last_name: 'Doe')
      expect(person.full_name).to eq('John Doe')
    end
  end

  describe '#formatted_member_number' do
    it "returns 'Non assigné' when no member number" do
      person = Person.new(member_number: nil)
      expect(person.formatted_member_number).to eq('Non assigné')
    end

    it 'formats member number when present' do
      person = Person.new(member_number: '25U001')
      allow(MemberManagementService).to receive(:parse_member_number).with('25U001').and_return({
                                                                                                  year: '2025', type: 'Basique', number: 1
                                                                                                })

      expect(person.formatted_member_number).to eq('2025 - Basique - #1')
    end
  end

  describe '#member_number_details' do
    it 'returns nil when no member number' do
      person = Person.new(member_number: nil)
      expect(person.member_number_details).to be_nil
    end

    it 'returns parsed member number details' do
      person = Person.new(member_number: '25U001')
      parsed_details = { year: '2025', type: 'Basique', number: 1 }
      allow(MemberManagementService).to receive(:parse_member_number).with('25U001').and_return(parsed_details)

      expect(person.member_number_details).to eq(parsed_details)
    end
  end

  describe '#has_user_account?' do
    it 'returns true when person has a user' do
      person = create(:person, :with_user)
      expect(person.has_user_account?).to be true
    end

    it 'returns false when person has no user' do
      person = create(:person)
      expect(person.has_user_account?).to be false
    end
  end

  describe '#current_membership' do
    it 'returns the current active membership' do
      person = create(:person)
      create(:membership, person: person, status: :inactive)
      current_membership = create(:membership, person: person, status: :active)

      expect(person.current_membership).to eq(current_membership)
    end

    it 'returns nil when no active membership' do
      person = create(:person)
      expect(person.current_membership).to be_nil
    end
  end

  describe '#has_active_membership?' do
    it 'returns true when person has active membership' do
      person = create(:person, :with_active_membership)
      expect(person.has_active_membership?).to be true
    end

    it 'returns false when person has no active membership' do
      person = create(:person)
      expect(person.has_active_membership?).to be false
    end
  end

  describe '#can_buy_contribution_formulas?' do
    it 'returns true for circus members' do
      person = create(:person, :with_circus_membership)
      expect(person.can_buy_contribution_formulas?).to be true
    end

    it 'returns false for basic members' do
      person = create(:person, :with_basic_membership)
      expect(person.can_buy_contribution_formulas?).to be false
    end

    it 'returns false when no active membership' do
      person = create(:person, :without_membership)
      expect(person.can_buy_contribution_formulas?).to be false
    end
  end

  describe '#change_member_number' do
    let(:person) { create(:person, member_number: '25U001') }

    before do
      allow(MemberManagementService).to receive(:generate_member_number).and_return('25C001')
    end

    it 'changes member number for circus type' do
      new_number = person.change_member_number('CIRQUE', 'Upgrade to circus')

      expect(new_number).to eq('25C001')
      expect(person.reload.member_number).to eq('25C001')
    end

    it 'creates member number history' do
      expect do
        person.change_member_number('CIRQUE', 'Upgrade to circus')
      end.to change(person.member_number_histories, :count).by(1)

      history = person.member_number_histories.last
      expect(history.member_number).to eq('25C001')
      expect(history.membership_type).to eq('Cirque')
      expect(history.notes).to eq('Upgrade to circus')
    end

    it 'returns false when no member number' do
      person.update!(member_number: nil, skip_membership_validation: true)
      result = person.change_member_number('CIRQUE')

      expect(result).to be false
    end
  end

  describe 'normalization' do
    it 'normalizes blank email to nil' do
      person = Person.new(first_name: 'John', last_name: 'Doe', email: '')
      person.valid?

      expect(person.email).to be_nil
    end
  end

  describe '#upgrade_contribution!' do
    let(:person) { create(:person, :with_circus_membership) }
    let(:pack10_plan) { create(:contribution_formula, :pack10) }
    let(:trimester_plan) { create(:contribution_formula, :trimester) }
    let(:annual_plan) { create(:contribution_formula, :annual) }
    let(:admin_user) { create(:user, system_role: :admin) }
    let!(:book) { create(:contribution, person: person, contribution_formula: pack10_plan, status: :active) }

    it 'upgrades pack10 to trimester with suspension' do
      result = person.upgrade_contribution!(
        from_contribution_id: book.id,
        to_formula_id: trimester_plan.id,
        payment_method: :cash,
        recorded_by: admin_user
      )

      expect(result[:old_contribution].reload.status).to eq('suspended')
      expect(result[:new_contribution]).to be_persisted
      expect(result[:payment]).to be_persisted
      expect(result[:credit_applied]).to eq(0) # Pack10 no credit
    end

    it 'upgrades trimester to annual with prorata' do
      trimester_book = create(:contribution, person: person, contribution_formula: trimester_plan,
                                             status: :active, expires_at: Date.current + 30.days, sessions_remaining: nil)

      result = person.upgrade_contribution!(
        from_contribution_id: trimester_book.id,
        to_formula_id: annual_plan.id,
        payment_method: :cash,
        recorded_by: admin_user
      )

      expect(result[:old_contribution].reload.status).to eq('suspended')
      expect(result[:new_contribution]).to be_persisted
      expect(result[:payment]).to be_persisted
      expect(result[:credit_applied]).to be > 0 # Prorata credit
    end

    it 'raises error if no circus membership' do
      basic_person = create(:person, :with_basic_membership)
      basic_book = create(:contribution, person: basic_person, contribution_formula: pack10_plan)

      expect do
        basic_person.upgrade_contribution!(
          from_contribution_id: basic_book.id,
          to_formula_id: trimester_plan.id,
          payment_method: :cash,
          recorded_by: admin_user
        )
      end.to raise_error('Adhésion Cirque active requise')
    end

    it 'raises error for invalid upgrade path' do
      expect do
        person.upgrade_contribution!(
          from_contribution_id: book.id,
          to_formula_id: pack10_plan.id, # Can't upgrade to same type
          payment_method: :cash,
          recorded_by: admin_user
        )
      end.to raise_error(/non autorisé/)
    end
  end

  describe '#safe_to_merge_with?' do
    let(:person) { create(:person) }
    let(:other_person) { create(:person) }

    it 'returns false when other_person is nil' do
      expect(person.safe_to_merge_with?(nil)).to be false
    end

    it 'returns false when merging with self' do
      expect(person.safe_to_merge_with?(person)).to be false
    end

    it 'returns true when both have no user' do
      expect(person.safe_to_merge_with?(other_person)).to be true
    end

    it 'returns true when only self has user' do
      create(:user, person: person)
      expect(person.safe_to_merge_with?(other_person)).to be true
    end

    it 'returns true when only other has user' do
      create(:user, person: other_person)
      expect(person.safe_to_merge_with?(other_person)).to be true
    end

    it 'returns true when both have same user' do
      user = create(:user, person: person)
      other_person.update(user: user)
      expect(person.safe_to_merge_with?(other_person)).to be true
    end

    it 'returns false when both have different users' do
      create(:user, person: person)
      create(:user, person: other_person)
      expect(person.safe_to_merge_with?(other_person)).to be false
    end
  end

  describe '#can_be_claimed_by?' do
    let(:person) { create(:person, email: 'test@example.com') }

    it 'returns false when person has a user' do
      create(:user, person: person)
      expect(person.can_be_claimed_by?('test@example.com')).to be false
    end

    it 'returns false when email is blank' do
      person.update(email: nil)
      expect(person.can_be_claimed_by?('test@example.com')).to be false
    end

    it "returns false when email doesn't match" do
      expect(person.can_be_claimed_by?('different@example.com')).to be false
    end

    it 'returns true when conditions are met' do
      expect(person.can_be_claimed_by?('test@example.com')).to be true
    end

    it 'handles case-insensitive email matching' do
      expect(person.can_be_claimed_by?('TEST@EXAMPLE.COM')).to be true
    end
  end

  describe '#has_financial_data?' do
    it 'returns false when no payments and no active memberships' do
      person = create(:person)
      expect(person.has_financial_data?).to be false
    end

    it 'returns true when person has payments' do
      person = create(:person)
      create(:payment, person: person)
      expect(person.has_financial_data?).to be true
    end

    it 'returns true when person has active membership' do
      person = create(:person, :with_active_membership)
      expect(person.has_financial_data?).to be true
    end

    it 'returns false when person has inactive membership but no payments' do
      person = create(:person)
      create(:membership, person: person, status: :inactive)
      expect(person.has_financial_data?).to be false
    end
  end

  describe '#archive! and #restore!' do
    let(:person) { create(:person) }

    it 'archives person without financial data' do
      expect do
        person.archive!
      end.to change { person.reload.archived? }.from(false).to(true)
      expect(person.deleted_at).to be_present
    end

    it 'does not archive person with financial data' do
      create(:payment, person: person)
      expect do
        result = person.archive!
        expect(result).to be false
      end.not_to(change { person.reload.deleted_at })
    end

    it 'does not archive person with active membership' do
      create(:membership, person: person, status: :active)
      expect do
        result = person.archive!
        expect(result).to be false
      end.not_to(change { person.reload.deleted_at })
    end

    it 'restores archived person' do
      person.update(deleted_at: 1.day.ago)
      expect do
        person.restore!
      end.to change { person.reload.deleted_at }.to(nil)
    end

    it 'uses SoftDeletable concern' do
      expect(person).to respond_to(:archived?)
      expect(person).to respond_to(:archive!)
      expect(person).to respond_to(:restore!)
      expect(person).to respond_to(:can_be_archived?)
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only non-archived persons' do
        active_person = create(:person)
        archived_person = create(:person, deleted_at: 1.day.ago)

        expect(Person.active).to include(active_person)
        expect(Person.active).not_to include(archived_person)
      end
    end

    describe '.archived' do
      it 'returns only archived persons' do
        active_person = create(:person)
        archived_person = create(:person, deleted_at: 1.day.ago)

        expect(Person.archived).not_to include(active_person)
        expect(Person.archived).to include(archived_person)
      end
    end

    describe '.with_expiring_membership' do
      it 'returns persons with membership expiring in next 30 days' do
        person1 = create(:person)
        person2 = create(:person)

        create(:membership, person: person1, status: :active, ended_at: 15.days.from_now)
        create(:membership, person: person2, status: :active, ended_at: 60.days.from_now)

        expect(Person.with_expiring_membership).to include(person1)
        expect(Person.with_expiring_membership).not_to include(person2)
      end
    end

    describe '.without_membership' do
      it 'returns persons with no memberships' do
        person_without = create(:person)
        person_with = create(:person, :with_active_membership)

        expect(Person.without_membership).to include(person_without)
        expect(Person.without_membership).not_to include(person_with)
      end
    end
  end
end
