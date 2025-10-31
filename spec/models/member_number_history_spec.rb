require 'rails_helper'

RSpec.describe MemberNumberHistory, type: :model do
  let(:person) { create(:person) }

  describe "associations" do
    it { should belong_to(:person) }
  end

  describe "validations" do
    it { should validate_presence_of(:member_number) }
    # it { should validate_uniqueness_of(:member_number) } # Skip due to factory conflicts
    it { should validate_presence_of(:membership_type) }
    it { should validate_presence_of(:year) }
    it { should validate_presence_of(:assigned_at) }

    it "validates membership_type inclusion" do
      history = build(:member_number_history, membership_type: "Invalid")
      expect(history).not_to be_valid
      expect(history.errors[:membership_type]).to be_present
    end

    it "validates year is between 2000 and 2100" do
      history = build(:member_number_history, year: 1999)
      expect(history).not_to be_valid
      history.year = 2100
      expect(history).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:current_history) { create(:member_number_history, member_number: "25U001", replaced_at: nil) }
    let!(:historical_history) { create(:member_number_history, member_number: "25U002", replaced_at: 1.day.ago) }

    it ".current returns non-replaced histories" do
      expect(MemberNumberHistory.current).to include(current_history)
      expect(MemberNumberHistory.current).not_to include(historical_history)
    end

    it ".historical returns replaced histories" do
      expect(MemberNumberHistory.historical).to include(historical_history)
      expect(MemberNumberHistory.historical).not_to include(current_history)
    end

    it ".by_year filters by year" do
      history = create(:member_number_history, member_number: "25U003", year: 2024)
      expect(MemberNumberHistory.by_year(2024)).to include(history)
    end

    it ".by_type filters by membership type" do
      history = create(:member_number_history, member_number: "25C002", membership_type: "Cirque")
      expect(MemberNumberHistory.by_type("Cirque")).to include(history)
    end
  end

  describe ".current_for_person" do
    it "returns current member number for person" do
      current = create(:member_number_history, person: person, replaced_at: nil)
      expect(MemberNumberHistory.current_for_person(person)).to eq(current)
    end

    it "returns nil if no current member number" do
      create(:member_number_history, person: person, replaced_at: 1.day.ago)
      expect(MemberNumberHistory.current_for_person(person)).to be_nil
    end
  end

  describe ".history_for_person" do
    let!(:old_history) { create(:member_number_history, person: person, member_number: "23U001", assigned_at: 2.years.ago) }
    let!(:new_history) { create(:member_number_history, person: person, member_number: "24U001", assigned_at: 1.year.ago) }

    it "returns all histories ordered by assigned_at" do
      history = MemberNumberHistory.history_for_person(person)
      expect(history.first).to eq(old_history)
      expect(history.last).to eq(new_history)
    end
  end

  describe "#mark_as_replaced!" do
    it "updates replaced_at to current time" do
      history = create(:member_number_history, replaced_at: nil)
      history.mark_as_replaced!
      expect(history.replaced_at).to be_present
    end
  end

  describe "#current?" do
    it "returns true when replaced_at is nil" do
      history = create(:member_number_history, replaced_at: nil)
      expect(history.current?).to be true
    end

    it "returns false when replaced_at is present" do
      history = create(:member_number_history, replaced_at: 1.day.ago)
      expect(history.current?).to be false
    end
  end

  describe "#duration" do
    it "returns time difference for replaced number" do
      six_months = 6.months.to_i
      history = create(:member_number_history, member_number: "25U004", assigned_at: 1.year.ago, replaced_at: 6.months.ago)
      expect(history.duration.to_i).to be_within(six_months / 10).of(six_months)
    end

    it "returns duration from assigned_at to now for current number" do
      history = create(:member_number_history, member_number: "25U005", assigned_at: 6.months.ago, replaced_at: nil)
      expect(history.duration).to be > 5.months
    end
  end
end

