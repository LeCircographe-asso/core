require 'rails_helper'

RSpec.describe BookOfEntry, type: :model do
  let(:circus_membership_type) { create(:membership_type, category: :circus_full) }
  let(:basic_membership_type) { create(:membership_type, category: :basic) }
  let(:person) { create(:person, :with_active_membership) }
  let(:pack10_plan) { create(:subscription_plan, duration: :pack10, sessions_count: 10, membership_type: circus_membership_type) }
  let(:day_plan) { create(:subscription_plan, duration: :day, sessions_count: 1, membership_type: circus_membership_type) }

  describe "validations" do
    it "validates presence of sessions_remaining" do
      book_of_entry = build(:book_of_entry, sessions_remaining: nil)
      expect(book_of_entry).not_to be_valid
      expect(book_of_entry.errors[:sessions_remaining]).to include("can't be blank")
    end

    it "validates presence of status" do
      book_of_entry = build(:book_of_entry, status: nil)
      expect(book_of_entry).not_to be_valid
      expect(book_of_entry.errors[:status]).to include("can't be blank")
    end

    it "validates presence of purchased_at" do
      book_of_entry = build(:book_of_entry, purchased_at: nil)
      expect(book_of_entry).not_to be_valid
      expect(book_of_entry.errors[:purchased_at]).to include("can't be blank")
    end

    it "validates presence of expires_at for non-pack10 plans" do
      book_of_entry = build(:book_of_entry, subscription_plan: day_plan, expires_at: nil)
      expect(book_of_entry).not_to be_valid
      expect(book_of_entry.errors[:expires_at]).to include("can't be blank")
    end

    it "does not validate presence of expires_at for pack10 plans" do
      book_of_entry = build(:book_of_entry, subscription_plan: pack10_plan, expires_at: nil)
      expect(book_of_entry).to be_valid
    end
  end

  describe "associations" do
    it "belongs to person" do
      book_of_entry = create(:book_of_entry, person: person)
      expect(book_of_entry.person).to eq(person)
    end

    it "belongs to subscription_plan" do
      book_of_entry = create(:book_of_entry, subscription_plan: pack10_plan)
      expect(book_of_entry.subscription_plan).to eq(pack10_plan)
    end
  end

  describe "enums" do
    it "defines status enum" do
      expect(BookOfEntry.statuses).to eq({
        'inactive' => 0,
        'active' => 1,
        'expired' => 2,
        'consumed' => 3
      })
    end
  end

  describe "#can_use?" do
    context "with active membership and remaining sessions" do
      let(:circus_person) { create(:person, :with_active_membership) }
      let(:book_of_entry) { create(:book_of_entry, person: circus_person, subscription_plan: pack10_plan, sessions_remaining: 5) }

      before do
        circus_person.current_membership.update!(membership_type: circus_membership_type)
      end

      it "returns true for pack10 with active circus membership" do
        expect(book_of_entry.can_use?).to be true
      end
    end

    context "with expired membership" do
      let(:expired_person) { create(:person, :with_expired_membership) }
      let(:book_of_entry) { create(:book_of_entry, person: expired_person, subscription_plan: pack10_plan, sessions_remaining: 5) }

      it "returns false when person has no active membership" do
        expect(book_of_entry.can_use?).to be false
      end
    end

    context "with basic membership" do
      let(:basic_person) { create(:person, :with_active_membership) }
      let(:book_of_entry) { create(:book_of_entry, person: basic_person, subscription_plan: pack10_plan, sessions_remaining: 5) }

      before do
        basic_person.current_membership.update!(membership_type: basic_membership_type)
      end

      it "returns false when person has basic membership instead of circus" do
        expect(book_of_entry.can_use?).to be false
      end
    end

    context "with no remaining sessions" do
      let(:circus_person) { create(:person, :with_active_membership) }
      let(:book_of_entry) { create(:book_of_entry, person: circus_person, subscription_plan: pack10_plan, sessions_remaining: 0) }

      before do
        circus_person.current_membership.update!(membership_type: circus_membership_type)
      end

      it "returns false when no sessions remaining" do
        expect(book_of_entry.can_use?).to be false
      end
    end

    context "with inactive status" do
      let(:circus_person) { create(:person, :with_active_membership) }
      let(:book_of_entry) { create(:book_of_entry, person: circus_person, subscription_plan: pack10_plan, sessions_remaining: 5, status: :inactive) }

      before do
        circus_person.current_membership.update!(membership_type: circus_membership_type)
      end

      it "returns false when status is inactive" do
        expect(book_of_entry.can_use?).to be false
      end
    end
  end

  describe "#expired?" do
    context "with pack10 plan" do
      let(:book_of_entry) { create(:book_of_entry, person: person, subscription_plan: pack10_plan) }

      it "never expires" do
        expect(book_of_entry.expired?).to be false
      end
    end

    context "with non-pack10 plan" do
      let(:book_of_entry) { create(:book_of_entry, person: person, subscription_plan: day_plan, expires_at: 1.day.ago) }

      it "expires when expires_at is in the past" do
        expect(book_of_entry.expired?).to be true
      end
    end

    context "with non-pack10 plan not expired" do
      let(:book_of_entry) { create(:book_of_entry, person: person, subscription_plan: day_plan, expires_at: 1.day.from_now) }

      it "does not expire when expires_at is in the future" do
        expect(book_of_entry.expired?).to be false
      end
    end
  end

  describe "#is_pack10?" do
    context "with pack10 plan" do
      let(:book_of_entry) { create(:book_of_entry, person: person, subscription_plan: pack10_plan) }

      it "returns true" do
        expect(book_of_entry.is_pack10?).to be true
      end
    end

    context "with non-pack10 plan" do
      let(:book_of_entry) { create(:book_of_entry, person: person, subscription_plan: day_plan) }

      it "returns false" do
        expect(book_of_entry.is_pack10?).to be false
      end
    end
  end

  describe "#use_session!" do
    let(:circus_person) { create(:person, :with_active_membership) }
    let(:book_of_entry) { create(:book_of_entry, person: circus_person, subscription_plan: pack10_plan, sessions_remaining: 3) }

    before do
      circus_person.current_membership.update!(membership_type: circus_membership_type)
    end

    context "when can_use? returns true" do
      it "decrements sessions_remaining" do
        expect { book_of_entry.use_session! }.to change { book_of_entry.sessions_remaining }.from(3).to(2)
      end

      it "changes status to consumed when no sessions remaining" do
        book_of_entry.update!(sessions_remaining: 1)
        expect { book_of_entry.use_session! }.to change { book_of_entry.status }.from('active').to('consumed')
      end
    end

    context "when can_use? returns false" do
      before { allow(book_of_entry).to receive(:can_use?).and_return(false) }

      it "does not decrement sessions_remaining" do
        expect { book_of_entry.use_session! }.not_to change { book_of_entry.sessions_remaining }
      end

      it "returns false" do
        expect(book_of_entry.use_session!).to be false
      end
    end
  end

  describe "#remaining_entries" do
    let(:book_of_entry) { create(:book_of_entry, person: person, subscription_plan: pack10_plan, sessions_remaining: 7) }

    it "returns sessions_remaining" do
      expect(book_of_entry.remaining_entries).to eq(7)
    end
  end
end
