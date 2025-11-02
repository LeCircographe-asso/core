require 'rails_helper'

RSpec.describe Person, type: :model do
  describe 'validations' do
    it "can be created" do
      person = Person.new(first_name: "John", last_name: "Doe")
      expect(person).to be_present
    end

    it "requires first_name" do
      person = Person.new(last_name: "Doe")
      expect(person).not_to be_valid
      expect(person.errors[:first_name]).to include("can't be blank")
    end

    it "requires last_name" do
      person = Person.new(first_name: "John")
      expect(person).not_to be_valid
      expect(person.errors[:last_name]).to include("can't be blank")
    end

    it "requires email if newsletter_subscribed is true" do
      person = Person.new(first_name: "John", last_name: "Doe", newsletter_subscribed: true)
      expect(person).not_to be_valid
      expect(person.errors[:email]).to include("can't be blank")
    end

    it "allows blank email if newsletter_subscribed is false" do
      person = Person.new(first_name: "John", last_name: "Doe", newsletter_subscribed: false)
      expect(person).to be_valid
    end

    it "validates email uniqueness" do
      create(:person, email: "test@example.com")
      person = Person.new(first_name: "John", last_name: "Doe", email: "test@example.com")
      expect(person).not_to be_valid
      expect(person.errors[:email]).to include("has already been taken")
    end

    it "validates phone uniqueness" do
      create(:person, phone: "0123456789")
      person = Person.new(first_name: "John", last_name: "Doe", phone: "0123456789")
      expect(person).not_to be_valid
      expect(person.errors[:phone]).to include("has already been taken")
    end

    it "validates member_number uniqueness" do
      create(:person, member_number: "25U001")
      person = Person.new(first_name: "John", last_name: "Doe", member_number: "25U001")
      expect(person).not_to be_valid
      expect(person.errors[:member_number]).to include("has already been taken")
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

    it "allows no active membership if skip_membership_validation is true" do
      person = create(:person)
      person.skip_membership_validation = true
      person.memberships.destroy_all
      
      expect(person).to be_valid
    end
  end

  describe 'associations' do
    it "can have a user account" do
      person = create(:person)
      user = create(:user, person: person)
      expect(person.user).to eq(user)
    end

    it "can have multiple memberships" do
      person = create(:person)
      membership1 = create(:membership, person: person, started_at: 1.year.ago, ended_at: 6.months.ago, status: :inactive)
      membership2 = create(:membership, person: person, started_at: 3.months.ago, ended_at: 9.months.from_now, status: :active)
      
      expect(person.memberships).to include(membership1, membership2)
    end

    it "can have multiple payments" do
      person = create(:person)
      payment1 = create(:payment, person: person)
      payment2 = create(:payment, person: person)
      
      expect(person.payments).to include(payment1, payment2)
    end

    it "can have book of entries" do
      person = create(:person)
      book_of_entry = create(:book_of_entry, person: person)
      
      expect(person.book_of_entries).to include(book_of_entry)
    end

    it "can have member number histories" do
      person = create(:person, member_number: "25U001")
      history = create(:member_number_history, person: person, member_number: "25U001")
      
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

    it "finds people with user accounts" do
      expect(Person.with_user_account).to include(person_with_user)
      expect(Person.with_user_account).not_to include(person_without_user)
    end

    it "finds people without user accounts" do
      expect(Person.without_user_account).to include(person_without_user)
      expect(Person.without_user_account).not_to include(person_with_user)
    end

    it "finds people with active memberships" do
      expect(Person.with_active_membership).to include(person_with_active_membership)
      expect(Person.with_active_membership).not_to include(person_without_membership)
    end

    it "finds people with expiring memberships" do
      expect(Person.with_expiring_membership).to include(person_with_expiring_membership)
    end

    it "finds people with expired memberships" do
      expect(Person.with_expired_membership).to include(person_with_expired_membership)
    end

    it "finds people without memberships" do
      expect(Person.without_membership).to include(person_without_membership)
    end

    it "searches by contact information" do
      person = create(:person, first_name: "John", last_name: "Doe", email: "john@example.com")
      
      expect(Person.search_by_contact("John")).to include(person)
      expect(Person.search_by_contact("Doe")).to include(person)
      expect(Person.search_by_contact("john@example.com")).to include(person)
    end

    it "filters by name" do
      person = create(:person, first_name: "John", last_name: "Doe")
      
      expect(Person.by_name("John")).to include(person)
      expect(Person.by_name("Doe")).to include(person)
    end

    it "filters adults and minors" do
      adult = create(:person, is_minor: false)
      minor = create(:person, is_minor: true)
      
      expect(Person.adults).to include(adult)
      expect(Person.adults).not_to include(minor)
      expect(Person.minors).to include(minor)
      expect(Person.minors).not_to include(adult)
    end
  end

  describe '#full_name' do
    it "returns first_name and last_name combined" do
      person = Person.new(first_name: "John", last_name: "Doe")
      expect(person.full_name).to eq("John Doe")
    end
  end

  describe '#formatted_member_number' do
    it "returns 'Non assigné' when no member number" do
      person = Person.new(member_number: nil)
      expect(person.formatted_member_number).to eq("Non assigné")
    end

    it "formats member number when present" do
      person = Person.new(member_number: "25U001")
      allow(MemberManagementService).to receive(:parse_member_number).with("25U001").and_return({
        year: "2025", type: "Basique", number: 1
      })
      
      expect(person.formatted_member_number).to eq("2025 - Basique - #1")
    end
  end

  describe '#member_number_details' do
    it "returns nil when no member number" do
      person = Person.new(member_number: nil)
      expect(person.member_number_details).to be_nil
    end

    it "returns parsed member number details" do
      person = Person.new(member_number: "25U001")
      parsed_details = { year: "2025", type: "Basique", number: 1 }
      allow(MemberManagementService).to receive(:parse_member_number).with("25U001").and_return(parsed_details)
      
      expect(person.member_number_details).to eq(parsed_details)
    end
  end

  describe '#has_user_account?' do
    it "returns true when person has a user" do
      person = create(:person, :with_user)
      expect(person.has_user_account?).to be true
    end

    it "returns false when person has no user" do
      person = create(:person)
      expect(person.has_user_account?).to be false
    end
  end

  describe '#current_membership' do
    it "returns the current active membership" do
      person = create(:person)
      old_membership = create(:membership, person: person, status: :inactive)
      current_membership = create(:membership, person: person, status: :active)
      
      expect(person.current_membership).to eq(current_membership)
    end

    it "returns nil when no active membership" do
      person = create(:person)
      expect(person.current_membership).to be_nil
    end
  end

  describe '#has_active_membership?' do
    it "returns true when person has active membership" do
      person = create(:person, :with_active_membership)
      expect(person.has_active_membership?).to be true
    end

    it "returns false when person has no active membership" do
      person = create(:person)
      expect(person.has_active_membership?).to be false
    end
  end

  describe '#can_buy_subscription_plans?' do
    it "returns true for circus members" do
      person = create(:person, :with_circus_membership)
      expect(person.can_buy_subscription_plans?).to be true
    end

    it "returns false for basic members" do
      person = create(:person, :with_basic_membership)
      expect(person.can_buy_subscription_plans?).to be false
    end

    it "returns false when no active membership" do
      person = create(:person, :without_membership)
      expect(person.can_buy_subscription_plans?).to be false
    end
  end

  describe '#change_member_number' do
    let(:person) { create(:person, member_number: "25U001") }

    before do
      allow(MemberManagementService).to receive(:generate_member_number).and_return("25C001")
    end

    it "changes member number for circus type" do
      new_number = person.change_member_number("CIRQUE", "Upgrade to circus")
      
      expect(new_number).to eq("25C001")
      expect(person.reload.member_number).to eq("25C001")
    end

    it "creates member number history" do
      expect {
        person.change_member_number("CIRQUE", "Upgrade to circus")
      }.to change(person.member_number_histories, :count).by(1)
      
      history = person.member_number_histories.last
      expect(history.member_number).to eq("25C001")
      expect(history.membership_type).to eq("Cirque")
      expect(history.notes).to eq("Upgrade to circus")
    end

    it "returns false when no member number" do
      person.update!(member_number: nil, skip_membership_validation: true)
      result = person.change_member_number("CIRQUE")
      
      expect(result).to be false
    end
  end

  describe 'normalization' do
    it "normalizes blank email to nil" do
      person = Person.new(first_name: "John", last_name: "Doe", email: "")
      person.valid?
      
      expect(person.email).to be_nil
    end
  end
  
end
