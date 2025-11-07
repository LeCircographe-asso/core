require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe 'validations' do
    it "can be created" do
      person = create(:person)
      membership_type = create(:membership_type)
      membership = Membership.new(person: person, membership_type: membership_type, status: :active)
      expect(membership).to be_present
    end

    it "requires a person" do
      membership_type = create(:membership_type)
      membership = Membership.new(membership_type: membership_type, status: :active)
      expect(membership).not_to be_valid
      expect(membership.errors[:person]).to include("must exist")
    end

    it "requires a membership_type" do
      person = create(:person)
      membership = Membership.new(person: person, status: :active)
      expect(membership).not_to be_valid
      expect(membership.errors[:membership_type]).to include("must exist")
    end

    it "requires started_at" do
      person = create(:person)
      membership_type = create(:membership_type)
      membership = Membership.new(person: person, membership_type: membership_type, status: :active, ended_at: Date.current + 1.year)
      expect(membership).not_to be_valid
      expect(membership.errors[:started_at]).to include("can't be blank")
    end

    it "requires ended_at" do
      person = create(:person)
      membership_type = create(:membership_type)
      membership = Membership.new(person: person, membership_type: membership_type, status: :active, started_at: Date.current)
      expect(membership).not_to be_valid
      expect(membership.errors[:ended_at]).to include("can't be blank")
    end

    it "requires status" do
      person = create(:person)
      membership_type = create(:membership_type)
      membership = Membership.new(person: person, membership_type: membership_type, started_at: Date.current, ended_at: Date.current + 1.year, status: nil)
      expect(membership).not_to be_valid
      expect(membership.errors[:status]).to include("can't be blank")
    end

    it "validates end_date is after start_date" do
      person = create(:person)
      membership_type = create(:membership_type)
      membership = Membership.new(
        person: person,
        membership_type: membership_type,
        started_at: Date.current + 1.year,
        ended_at: Date.current,
        status: :active
      )
      expect(membership).not_to be_valid
      expect(membership.errors[:ended_at]).to include("must be after start date")
    end

    it "prevents overlapping active memberships" do
      person = create(:person)
      membership_type = create(:membership_type)

      # Créer une première adhésion active
      create(:membership, person: person, membership_type: membership_type, status: :active,
             started_at: Date.current, ended_at: Date.current + 1.year)

      # Tenter de créer une adhésion qui chevauche
      overlapping_membership = Membership.new(
        person: person,
        membership_type: membership_type,
        status: :active,
        started_at: Date.current + 6.months,
        ended_at: Date.current + 18.months
      )

      expect(overlapping_membership).not_to be_valid
      expect(overlapping_membership.errors[:base]).to include("Person already has an active membership during this period")
    end

    it "allows overlapping memberships with different statuses" do
      person = create(:person)
      membership_type = create(:membership_type)

      # Créer une première adhésion inactive
      create(:membership, person: person, membership_type: membership_type, status: :inactive,
             started_at: Date.current, ended_at: Date.current + 1.year)

      # Créer une nouvelle adhésion active qui chevauche
      new_membership = Membership.new(
        person: person,
        membership_type: membership_type,
        status: :active,
        started_at: Date.current + 6.months,
        ended_at: Date.current + 18.months
      )

      expect(new_membership).to be_valid
    end

    it "has valid status values" do
      person = create(:person)
      membership_type = create(:membership_type)
      membership = Membership.new(person: person, membership_type: membership_type, status: :active)
      expect(membership.status).to eq("active")
    end
  end

  describe 'associations' do
    it "belongs to a person" do
      person = create(:person)
      membership = create(:membership, person: person)
      expect(membership.person).to eq(person)
    end

    it "belongs to a membership_type" do
      membership_type = create(:membership_type)
      membership = create(:membership, membership_type: membership_type)
      expect(membership.membership_type).to eq(membership_type)
    end
  end

  describe 'scopes' do
    let!(:current_membership) { create(:membership, status: :active, started_at: Date.current - 1.month, ended_at: Date.current + 11.months) }
    let!(:past_membership) { create(:membership, status: :active, started_at: Date.current - 1.year, ended_at: Date.current - 1.month) }
    let!(:future_membership) { create(:membership, status: :active, started_at: Date.current + 1.month, ended_at: Date.current + 13.months) }
    let!(:inactive_membership) { create(:membership, status: :inactive) }

    it "finds current memberships" do
      expect(Membership.current).to include(current_membership)
      expect(Membership.current).not_to include(past_membership, future_membership)
    end

    it "finds active memberships" do
      expect(Membership.active).to include(current_membership, past_membership, future_membership)
      expect(Membership.active).not_to include(inactive_membership)
    end
  end

  describe '#expired?' do
    it "returns true when status is expired" do
      membership = create(:membership, status: :expired)
      expect(membership.expired?).to be true
    end

    it "returns false when status is active" do
      membership = create(:membership, status: :active)
      expect(membership.expired?).to be false
    end

    # Note: expired? checks status, not dates. Date-based expiry is handled by scopes
  end

  describe '#basic?' do
    it "returns true for basic membership type" do
      membership_type = create(:membership_type, category: :basic)
      membership = create(:membership, membership_type: membership_type)
      expect(membership.basic?).to be true
    end

    it "returns false for circus membership type" do
      membership_type = create(:membership_type, category: :circus)
      membership = create(:membership, membership_type: membership_type)
      expect(membership.basic?).to be false
    end
  end

  describe '#circus?' do
    it "returns true for circus membership type (Full tarif)" do
      membership_type = create(:membership_type, :circus)
      membership = create(:membership, membership_type: membership_type)
      expect(membership.circus?).to be true
    end

    it "returns true for circus membership type (Reduced tarif)" do
      membership_type = create(:membership_type, :circus_reduced)
      membership = create(:membership, membership_type: membership_type)
      expect(membership.circus?).to be true
    end

    it "returns false for basic membership type" do
      membership_type = create(:membership_type, category: :basic)
      membership = create(:membership, membership_type: membership_type)
      expect(membership.circus?).to be false
    end
  end

  describe '#can_upgrade_to?' do
    let(:person) { create(:person) }
    let(:basic_type) { create(:membership_type, category: :basic) }
    let(:circus_full_type) { create(:membership_type, :circus) }
    let(:circus_reduced_type) { create(:membership_type, :circus_reduced) }

    it "allows basic to upgrade to circus (Full tarif)" do
      membership = create(:membership, person: person, membership_type: basic_type)
      expect(membership.can_upgrade_to?(circus_full_type)).to be true
    end

    it "allows basic to upgrade to circus (Reduced tarif)" do
      membership = create(:membership, person: person, membership_type: basic_type)
      expect(membership.can_upgrade_to?(circus_reduced_type)).to be true
    end

    it "allows circus Full to upgrade to circus Reduced" do
      membership = create(:membership, person: person, membership_type: circus_full_type)
      expect(membership.can_upgrade_to?(circus_reduced_type)).to be true
    end

    it "allows circus Reduced to upgrade to circus Full" do
      membership = create(:membership, person: person, membership_type: circus_reduced_type)
      expect(membership.can_upgrade_to?(circus_full_type)).to be true
    end

    it "prevents upgrade to the same type" do
      membership = create(:membership, person: person, membership_type: basic_type)
      expect(membership.can_upgrade_to?(basic_type)).to be false
    end

    it "prevents circus to downgrade to basic" do
      membership = create(:membership, person: person, membership_type: circus_full_type)
      expect(membership.can_upgrade_to?(basic_type)).to be false
    end
  end

  describe '#upgrade_to!' do
    let(:person) { create(:person) }
    let(:basic_type) { create(:membership_type, category: :basic) }
    let(:circus_type) { create(:membership_type, category: :circus) }
    let(:original_first_joined_at) { Date.current - 6.months }

    it "upgrades membership successfully" do
      original_membership = create(:membership,
        person: person,
        membership_type: basic_type,
        status: :active,
        first_joined_at: original_first_joined_at
      )

      new_membership = original_membership.upgrade_to!(circus_type)

      expect(new_membership).to be_persisted
      expect(new_membership.person).to eq(person)
      expect(new_membership.membership_type).to eq(circus_type)
      expect(new_membership.status).to eq("active")
      expect(new_membership.first_joined_at).to eq(original_first_joined_at)
    end

    it "preserves first_joined_at date" do
      original_membership = create(:membership,
        person: person,
        membership_type: basic_type,
        status: :active,
        first_joined_at: original_first_joined_at
      )

      new_membership = original_membership.upgrade_to!(circus_type)

      expect(new_membership.first_joined_at).to eq(original_first_joined_at)
    end

    it "marks original membership as inactive" do
      original_membership = create(:membership,
        person: person,
        membership_type: basic_type,
        status: :active
      )

      original_membership.upgrade_to!(circus_type)

      expect(original_membership.reload.status).to eq("inactive")
    end

    it "sets correct dates for new membership" do
      original_membership = create(:membership,
        person: person,
        membership_type: basic_type,
        status: :active
      )

      new_membership = original_membership.upgrade_to!(circus_type)

      expect(new_membership.started_at).to eq(Date.current)
      expect(new_membership.ended_at).to eq(Date.current + 1.year)
    end

    it "raises error for invalid upgrade" do
      original_membership = create(:membership,
        person: person,
        membership_type: basic_type,
        status: :active
      )

      expect {
        original_membership.upgrade_to!(basic_type)
      }.to raise_error("Cannot upgrade to this membership type")
    end

    it "uses custom start date when provided" do
      custom_start_date = Date.current + 1.month
      original_membership = create(:membership,
        person: person,
        membership_type: basic_type,
        status: :active
      )

      new_membership = original_membership.upgrade_to!(circus_type, custom_start_date)

      expect(new_membership.started_at).to eq(custom_start_date)
      expect(new_membership.ended_at).to eq(custom_start_date + 1.year)
    end
  end
end
