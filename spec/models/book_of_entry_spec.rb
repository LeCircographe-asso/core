require 'rails_helper'

RSpec.describe BookOfEntry, type: :model do
  let(:circus_membership_type) { create(:membership_type, :circus_full) }
  let(:basic_membership_type) { create(:membership_type, :basic) }
  let(:person) { create(:person, :with_active_membership) }
  let(:pack10_plan) { create(:subscription_plan, :pack10, membership_type: circus_membership_type) }
  let(:day_plan) { create(:subscription_plan, :day, membership_type: circus_membership_type) }
  let(:trimester_plan) { create(:subscription_plan, :trimester, membership_type: circus_membership_type) }
  let(:annual_plan) { create(:subscription_plan, :annual, membership_type: circus_membership_type) }

  describe "validations" do
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

    describe "conditional validations on sessions_remaining" do
      context "for pack10 plans" do
        it "requires sessions_remaining to be present and positive" do
          book_of_entry = build(:book_of_entry, subscription_plan: pack10_plan, sessions_remaining: nil)
          expect(book_of_entry).not_to be_valid
          expect(book_of_entry.errors[:sessions_remaining]).to be_present
        end
      end

      context "for day plans" do
        it "requires sessions_remaining to be present and positive" do
          book_of_entry = build(:book_of_entry, subscription_plan: day_plan, sessions_remaining: nil)
          expect(book_of_entry).not_to be_valid
          expect(book_of_entry.errors[:sessions_remaining]).to be_present
        end
      end

      context "for trimester/annual plans (unlimited)" do
        it "does not require sessions_remaining" do
          book_of_entry = build(:book_of_entry, subscription_plan: trimester_plan, sessions_remaining: nil)
          expect(book_of_entry).to be_valid
        end

        it "prevents sessions_remaining from being set" do
          book_of_entry = build(:book_of_entry, subscription_plan: annual_plan, sessions_remaining: 10)
          expect(book_of_entry).not_to be_valid
          expect(book_of_entry.errors[:sessions_remaining]).to include("doit être vide pour les abonnements illimités")
        end
      end
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

    context "with expired book (not pack10)" do
      let(:circus_person) { create(:person, :with_active_membership) }
      let(:expired_book) { create(:book_of_entry, person: circus_person, subscription_plan: day_plan, 
                                  sessions_remaining: 5, expires_at: 1.week.ago) }

      before do
        circus_person.current_membership.update!(membership_type: circus_membership_type)
      end

      it "returns false when book is expired" do
        expect(expired_book.can_use?).to be false
      end
    end

    context "with pack10 that would be expired but is pack10" do
      let(:circus_person) { create(:person, :with_active_membership) }
      # Pack10 never expires, so even old ones are usable
      let(:old_pack10) { create(:book_of_entry, person: circus_person, subscription_plan: pack10_plan, 
                               sessions_remaining: 5, purchased_at: 5.years.ago) }

      before do
        circus_person.current_membership.update!(membership_type: circus_membership_type)
      end

      it "returns true for old pack10 (never expires)" do
        expect(old_pack10.can_use?).to be true
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

  describe "#has_session_limit?" do
    it "returns true for pack10 plans" do
      book_of_entry = build(:book_of_entry, subscription_plan: pack10_plan)
      expect(book_of_entry.has_session_limit?).to be true
    end

    it "returns true for day plans" do
      book_of_entry = build(:book_of_entry, subscription_plan: day_plan)
      expect(book_of_entry.has_session_limit?).to be true
    end

    it "returns false for trimester plans" do
      book_of_entry = build(:book_of_entry, subscription_plan: trimester_plan)
      expect(book_of_entry.has_session_limit?).to be false
    end

    it "returns false for annual plans" do
      book_of_entry = build(:book_of_entry, subscription_plan: annual_plan)
      expect(book_of_entry.has_session_limit?).to be false
    end
  end

  describe "#expired? for day plans" do
    it "considers Time.current vs end_of_day for day plans" do
      # Day plan expired 2 days ago should be expired
      expired_book = create(:book_of_entry, person: person, subscription_plan: day_plan, 
                           expires_at: 2.days.ago.end_of_day)
      expect(expired_book.expired?).to be true
      
      # Day plan expiring tomorrow should not be expired
      future_book = create(:book_of_entry, person: person, subscription_plan: day_plan,
                          expires_at: 1.day.from_now.end_of_day)
      expect(future_book.expired?).to be false
    end
  end

  describe "scopes" do
    let!(:active_book) { create(:book_of_entry, :active, person: person, subscription_plan: pack10_plan, sessions_remaining: 5, expires_at: nil) }
    let!(:consumed_book) { create(:book_of_entry, :consumed, person: person, subscription_plan: pack10_plan, sessions_remaining: 0, expires_at: nil) }
    let!(:expired_book) { create(:book_of_entry, :expired, person: person, subscription_plan: day_plan, expires_at: 1.week.ago) }

    describe ".active" do
      it "returns only active books" do
        expect(BookOfEntry.active).to include(active_book)
        expect(BookOfEntry.active).not_to include(consumed_book, expired_book)
      end
    end

    describe ".consumed" do
      it "returns only consumed books" do
        expect(BookOfEntry.consumed).to include(consumed_book)
        expect(BookOfEntry.consumed).not_to include(active_book, expired_book)
      end
    end

    describe ".expired" do
      it "returns only expired books" do
        expect(BookOfEntry.expired).to include(expired_book)
        expect(BookOfEntry.expired).not_to include(active_book, consumed_book)
      end
    end

    describe ".expired_by_date" do
      it "returns books expired by date" do
        expect(BookOfEntry.expired_by_date).to include(expired_book)
        expect(BookOfEntry.expired_by_date).not_to include(active_book, consumed_book)
      end
    end

    describe ".not_expired_by_date" do
      it "returns books not expired by date" do
        not_expired = BookOfEntry.not_expired_by_date
        expect(not_expired).to include(active_book, consumed_book)
        expect(not_expired).not_to include(expired_book)
      end
    end

    describe ".with_expiration" do
      it "returns books with expiration date" do
        expect(BookOfEntry.with_expiration).to include(expired_book)
      end
    end

    describe ".without_expiration" do
      it "returns books without expiration date" do
        expect(BookOfEntry.without_expiration).to include(active_book, consumed_book)
      end
    end

    describe ".usable" do
      it "returns books that can be used" do
        usable = BookOfEntry.usable
        expect(usable).to include(active_book)
        expect(usable).not_to include(consumed_book, expired_book)
      end

      it "excludes books with no sessions remaining" do
        used_book = create(:book_of_entry, :active, person: person, subscription_plan: pack10_plan, 
                          sessions_remaining: 0, expires_at: nil)
        expect(BookOfEntry.usable).not_to include(used_book)
      end
    end
  end

end
