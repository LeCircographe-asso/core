require 'rails_helper'

RSpec.describe Contribution, type: :model do
  let(:circus_membership_type) { create(:membership_type, category: :circus) }
  let(:basic_membership_type) { create(:membership_type, :basic) }
  let(:person) { create(:person, :with_active_membership) }
  let(:pack10_plan) { create(:contribution_formula, :pack10, membership_type: circus_membership_type) }
  let(:day_plan) { create(:contribution_formula, :day, membership_type: circus_membership_type) }
  let(:trimester_plan) { create(:contribution_formula, :trimester, membership_type: circus_membership_type) }
  let(:annual_plan) { create(:contribution_formula, :annual, membership_type: circus_membership_type) }

  describe 'business defaults' do
    it 'instantiates pack10 books by default' do
      book = create(:contribution)

      expect(book.contribution_formula.duration).to eq('pack10')
      expect(book.sessions_remaining).to eq(book.contribution_formula.sessions_count)
      expect(book.expires_at).to be_nil
    end
  end

  describe 'validations' do
    it 'validates presence of status' do
      contribution = build(:contribution, status: nil)
      expect(contribution).not_to be_valid
      expect(contribution.errors[:status]).to include("can't be blank")
    end

    it 'validates presence of purchased_at' do
      contribution = build(:contribution, purchased_at: nil)
      expect(contribution).not_to be_valid
      expect(contribution.errors[:purchased_at]).to include("can't be blank")
    end

    it 'validates presence of expires_at for non-pack10 plans' do
      contribution = build(:contribution, contribution_formula: day_plan, expires_at: nil)
      expect(contribution).not_to be_valid
      expect(contribution.errors[:expires_at]).to include("can't be blank")
    end

    it 'does not validate presence of expires_at for pack10 plans' do
      contribution = build(:contribution, contribution_formula: pack10_plan, expires_at: nil)
      expect(contribution).to be_valid
    end

    describe 'conditional validations on sessions_remaining' do
      context 'for pack10 plans' do
        it 'requires sessions_remaining to be present and positive' do
          contribution = build(:contribution, contribution_formula: pack10_plan, sessions_remaining: nil)
          expect(contribution).not_to be_valid
          expect(contribution.errors[:sessions_remaining]).to be_present
        end
      end

      context 'for day plans' do
        it 'requires sessions_remaining to be present and positive' do
          contribution = build(:contribution, contribution_formula: day_plan, sessions_remaining: nil)
          expect(contribution).not_to be_valid
          expect(contribution.errors[:sessions_remaining]).to be_present
        end
      end

      context 'for trimester/annual plans (unlimited)' do
        it 'does not require sessions_remaining' do
          contribution = build(
            :contribution,
            contribution_formula: trimester_plan,
            sessions_remaining: nil,
            expires_at: 3.months.from_now
          )
          expect(contribution).to be_valid
        end

        it 'prevents sessions_remaining from being set' do
          contribution = build(
            :contribution,
            contribution_formula: annual_plan,
            sessions_remaining: 10,
            expires_at: 1.year.from_now
          )
          expect(contribution).not_to be_valid
          expect(contribution.errors[:sessions_remaining]).to include('doit être vide pour les cotisations illimitées')
        end
      end
    end
  end

  describe 'associations' do
    it 'belongs to person' do
      contribution = create(:contribution, person: person)
      expect(contribution.person).to eq(person)
    end

    it 'belongs to contribution_formula' do
      contribution = create(:contribution, contribution_formula: pack10_plan)
      expect(contribution.contribution_formula).to eq(pack10_plan)
    end
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(Contribution.statuses).to eq({
                                            'inactive' => 0,
                                            'active' => 1,
                                            'expired' => 2,
                                            'consumed' => 3,
                                            'suspended' => 4
                                          })
    end
  end

  describe '#can_use?' do
    context 'with active membership and remaining sessions' do
      let(:circus_person) { create(:person, :with_active_membership) }
      let(:contribution) { create(:contribution, person: circus_person, contribution_formula: pack10_plan, sessions_remaining: 5) }

      before do
        circus_person.current_membership.update!(membership_type: circus_membership_type)
      end

      it 'returns true for pack10 with active circus membership' do
        expect(contribution.can_use?).to be true
      end
    end

    context 'with expired membership' do
      let(:expired_person) { create(:person, :with_expired_membership) }
      let(:contribution) { create(:contribution, person: expired_person, contribution_formula: pack10_plan, sessions_remaining: 5) }

      it 'returns false when person has no active membership' do
        expect(contribution.can_use?).to be false
      end
    end

    context 'with basic membership' do
      let(:basic_person) { create(:person, :with_active_membership) }
      let(:contribution) { create(:contribution, person: basic_person, contribution_formula: pack10_plan, sessions_remaining: 5) }

      before do
        basic_person.current_membership.update!(membership_type: basic_membership_type)
      end

      it 'returns false when person has basic membership instead of circus' do
        expect(contribution.can_use?).to be false
      end
    end

    context 'with no remaining sessions' do
      let(:circus_person) { create(:person, :with_active_membership) }
      let(:contribution) { create(:contribution, person: circus_person, contribution_formula: pack10_plan, sessions_remaining: 0) }

      before do
        circus_person.current_membership.update!(membership_type: circus_membership_type)
      end

      it 'returns false when no sessions remaining' do
        expect(contribution.can_use?).to be false
      end
    end

    context 'with inactive status' do
      let(:circus_person) { create(:person, :with_active_membership) }
      let(:contribution) { create(:contribution, person: circus_person, contribution_formula: pack10_plan, sessions_remaining: 5, status: :inactive) }

      before do
        circus_person.current_membership.update!(membership_type: circus_membership_type)
      end

      it 'returns false when status is inactive' do
        expect(contribution.can_use?).to be false
      end
    end

    context 'with expired book (not pack10)' do
      let(:circus_person) { create(:person, :with_active_membership) }
      let(:expired_book) do
        create(:contribution, person: circus_person, contribution_formula: day_plan,
                              sessions_remaining: 5, expires_at: 1.week.ago)
      end

      before do
        circus_person.current_membership.update!(membership_type: circus_membership_type)
      end

      it 'returns false when book is expired' do
        expect(expired_book.can_use?).to be false
      end
    end

    context 'with pack10 that would be expired but is pack10' do
      let(:circus_person) { create(:person, :with_active_membership) }
      # Pack10 never expires, so even old ones are usable
      let(:old_pack10) do
        create(:contribution, person: circus_person, contribution_formula: pack10_plan,
                              sessions_remaining: 5, purchased_at: 5.years.ago)
      end

      before do
        circus_person.current_membership.update!(membership_type: circus_membership_type)
      end

      it 'returns true for old pack10 (never expires)' do
        expect(old_pack10.can_use?).to be true
      end
    end
  end

  describe '#expired?' do
    context 'with pack10 plan' do
      let(:contribution) { create(:contribution, person: person, contribution_formula: pack10_plan) }

      it 'never expires' do
        expect(contribution.expired?).to be false
      end
    end

    context 'with non-pack10 plan' do
      let(:contribution) { create(:contribution, person: person, contribution_formula: day_plan, expires_at: 1.day.ago) }

      it 'expires when expires_at is in the past' do
        expect(contribution.expired?).to be true
      end
    end

    context 'with non-pack10 plan not expired' do
      let(:contribution) { create(:contribution, person: person, contribution_formula: day_plan, expires_at: 1.day.from_now) }

      it 'does not expire when expires_at is in the future' do
        expect(contribution.expired?).to be false
      end
    end
  end

  describe '#is_pack10?' do
    context 'with pack10 plan' do
      let(:contribution) { create(:contribution, person: person, contribution_formula: pack10_plan) }

      it 'returns true' do
        expect(contribution.is_pack10?).to be true
      end
    end

    context 'with non-pack10 plan' do
      let(:contribution) { create(:contribution, person: person, contribution_formula: day_plan, expires_at: 1.day.from_now) }

      it 'returns false' do
        expect(contribution.is_pack10?).to be false
      end
    end
  end

  describe '#use_session!' do
    let(:circus_person) { create(:person, :with_active_membership) }
    let(:contribution) { create(:contribution, person: circus_person, contribution_formula: pack10_plan, sessions_remaining: 3) }

    before do
      circus_person.current_membership.update!(membership_type: circus_membership_type)
    end

    context 'when can_use? returns true' do
      it 'decrements sessions_remaining' do
        expect { contribution.use_session! }.to change { contribution.sessions_remaining }.from(3).to(2)
      end

      it 'changes status to consumed when no sessions remaining' do
        contribution.update!(sessions_remaining: 1)
        expect { contribution.use_session! }.to change { contribution.status }.from('active').to('consumed')
      end
    end

    context 'when can_use? returns false' do
      before { allow(contribution).to receive(:can_use?).and_return(false) }

      it 'does not decrement sessions_remaining' do
        expect { contribution.use_session! }.not_to(change { contribution.sessions_remaining })
      end

      it 'returns false' do
        expect(contribution.use_session!).to be false
      end
    end

    context 'with day plan' do
      let(:circus_person) { create(:person, :with_circus_membership) }
      let(:day_plan) { create(:contribution_formula, :day, membership_type: circus_membership_type) }
      let(:day_book) do
        create(:contribution, person: circus_person, contribution_formula: day_plan, sessions_remaining: 1, expires_at: Date.current.end_of_day)
      end

      it 'consumes the pass and marks it consumed' do
        expect { day_book.use_session! }.to change { day_book.reload.status }.from('active').to('consumed')
        expect(day_book.sessions_remaining).to eq(0)
      end
    end

    context 'with trimester plan (unlimited)' do
      let(:circus_person) { create(:person, :with_circus_membership) }
      let(:trimester_plan) { create(:contribution_formula, :trimester, membership_type: circus_membership_type) }
      let(:trimester_book) do
        create(:contribution, person: circus_person, contribution_formula: trimester_plan, sessions_remaining: nil, expires_at: 3.months.from_now)
      end

      it 'does not alter sessions or status' do
        expect { trimester_book.use_session! }.not_to(change { [trimester_book.reload.sessions_remaining, trimester_book.status] })
      end
    end

    context 'with annual plan (unlimited)' do
      let(:circus_person) { create(:person, :with_circus_membership) }
      let(:annual_plan) { create(:contribution_formula, :annual, membership_type: circus_membership_type) }
      let(:annual_book) do
        create(:contribution, person: circus_person, contribution_formula: annual_plan, sessions_remaining: nil, expires_at: 1.year.from_now)
      end

      it 'keeps the book active' do
        expect { annual_book.use_session! }.not_to(change { annual_book.reload.status })
        expect(annual_book.sessions_remaining).to be_nil
      end
    end
  end

  describe '#remaining_entries' do
    let(:contribution) { create(:contribution, person: person, contribution_formula: pack10_plan, sessions_remaining: 7) }

    it 'returns sessions_remaining' do
      expect(contribution.remaining_entries).to eq(7)
    end
  end

  describe '#has_session_limit?' do
    it 'returns true for pack10 plans' do
      contribution = build(:contribution, contribution_formula: pack10_plan)
      expect(contribution.has_session_limit?).to be true
    end

    it 'returns true for day plans' do
      contribution = build(:contribution, contribution_formula: day_plan)
      expect(contribution.has_session_limit?).to be true
    end

    it 'returns false for trimester plans' do
      contribution = build(:contribution, contribution_formula: trimester_plan)
      expect(contribution.has_session_limit?).to be false
    end

    it 'returns false for annual plans' do
      contribution = build(:contribution, contribution_formula: annual_plan)
      expect(contribution.has_session_limit?).to be false
    end
  end

  describe '#expired? for day plans' do
    it 'considers Time.current vs end_of_day for day plans' do
      # Day plan expired 2 days ago should be expired
      expired_book = create(:contribution, person: person, contribution_formula: day_plan,
                                           expires_at: 2.days.ago.end_of_day)
      expect(expired_book.expired?).to be true

      # Day plan expiring tomorrow should not be expired
      future_book = create(:contribution, person: person, contribution_formula: day_plan,
                                          expires_at: 1.day.from_now.end_of_day)
      expect(future_book.expired?).to be false
    end
  end

  describe 'scopes' do
    let!(:active_book) { create(:contribution, :active, person: person, contribution_formula: pack10_plan, sessions_remaining: 5, expires_at: nil) }
    let!(:consumed_book) { create(:contribution, :consumed, person: person, contribution_formula: pack10_plan, sessions_remaining: 0, expires_at: nil) }
    let!(:expired_book) { create(:contribution, :expired, person: person, contribution_formula: day_plan, expires_at: 1.week.ago) }

    describe '.active' do
      it 'returns only active books' do
        expect(Contribution.active).to include(active_book)
        expect(Contribution.active).not_to include(consumed_book, expired_book)
      end
    end

    describe '.consumed' do
      it 'returns only consumed books' do
        expect(Contribution.consumed).to include(consumed_book)
        expect(Contribution.consumed).not_to include(active_book, expired_book)
      end
    end

    describe '.expired' do
      it 'returns only expired books' do
        expect(Contribution.expired).to include(expired_book)
        expect(Contribution.expired).not_to include(active_book, consumed_book)
      end
    end

    describe '.expired_by_date' do
      it 'returns books expired by date' do
        expect(Contribution.expired_by_date).to include(expired_book)
        expect(Contribution.expired_by_date).not_to include(active_book, consumed_book)
      end
    end

    describe '.not_expired_by_date' do
      it 'returns books not expired by date' do
        not_expired = Contribution.not_expired_by_date
        expect(not_expired).to include(active_book, consumed_book)
        expect(not_expired).not_to include(expired_book)
      end
    end

    describe '.with_expiration' do
      it 'returns books with expiration date' do
        expect(Contribution.with_expiration).to include(expired_book)
      end
    end
  end

  describe 'Statusable concern methods' do
    let(:book) { create(:contribution, status: :active) }

    describe '#status_humanized' do
      it 'returns humanized status' do
        expect(book.status_humanized).to eq('Actif')
      end

      it 'returns humanized status for expired' do
        expired_book = create(:contribution, status: :expired)
        expect(expired_book.status_humanized).to eq('Expiré')
      end

      it 'returns humanized status for consumed' do
        consumed_book = create(:contribution, status: :consumed)
        expect(consumed_book.status_humanized).to eq('Consommé')
      end
    end

    describe '#active?' do
      it 'returns true for active status' do
        expect(book.active?).to be true
      end

      it 'returns false for inactive status' do
        inactive_book = create(:contribution, status: :inactive)
        expect(inactive_book.active?).to be false
      end
    end

    describe '#inactive?' do
      it 'returns true for inactive status' do
        inactive_book = create(:contribution, status: :inactive)
        expect(inactive_book.inactive?).to be true
      end
    end

    describe '#status_badge_class' do
      it 'returns badge class for active status' do
        expect(book.status_badge_class).to eq('bg-green-100 text-green-800')
      end

      it 'returns badge class for expired status' do
        expired_book = create(:contribution, status: :expired)
        expect(expired_book.status_badge_class).to eq('bg-red-100 text-red-800')
      end
    end
  end

  describe 'Dateable concern methods' do
    let(:book) { create(:contribution, purchased_at: Date.current.beginning_of_day + 12.hours, expires_at: Date.current + 1.month) }

    describe '#formatted_date' do
      it 'formats purchased_at date' do
        formatted = book.formatted_date(:purchased_at)
        expect(formatted).to match(%r{\d{2}/\d{2}/\d{4}})
      end

      it 'formats expires_at date' do
        formatted = book.formatted_date(:expires_at)
        expect(formatted).to match(%r{\d{2}/\d{2}/\d{4}})
      end
    end

    describe '#formatted_datetime' do
      it 'formats purchased_at datetime' do
        formatted = book.formatted_datetime(:purchased_at)
        expect(formatted).to match(%r{\d{2}/\d{2}/\d{4} à \d{2}:\d{2}})
      end
    end

    describe '#today?' do
      it 'returns true for book purchased today' do
        expect(book.today?(:purchased_at)).to be true
      end

      it 'returns false for book purchased yesterday' do
        old_book = create(:contribution, purchased_at: Date.yesterday.beginning_of_day + 12.hours)
        expect(old_book.today?(:purchased_at)).to be false
      end
    end

    describe '#this_week?' do
      it 'returns true for book purchased this week' do
        expect(book.this_week?(:purchased_at)).to be true
      end
    end

    describe '#this_month?' do
      it 'returns true for book purchased this month' do
        expect(book.this_month?(:purchased_at)).to be true
      end
    end

    describe '#expired? (custom method - checks date, not status)' do
      it 'overrides Statusable expired? method' do
        # Contribution's expired? checks expires_at date, not status
        future_book = create(:contribution, contribution_formula: day_plan, expires_at: Date.current + 1.day, status: :active)
        expect(future_book.expired?).to be false

        past_book = create(:contribution, contribution_formula: day_plan, expires_at: Date.current - 1.day, status: :active)
        expect(past_book.expired?).to be true
      end
    end

    describe '.without_expiration' do
      let!(:active_book_no_exp) { create(:contribution, :active, person: person, contribution_formula: pack10_plan, sessions_remaining: 5, expires_at: nil) }
      let!(:consumed_book_no_exp) { create(:contribution, :consumed, person: person, contribution_formula: pack10_plan, sessions_remaining: 0, expires_at: nil) }

      it 'returns books without expiration date' do
        expect(Contribution.without_expiration).to include(active_book_no_exp, consumed_book_no_exp)
      end
    end

    describe '.usable' do
      let!(:usable_book) { create(:contribution, :active, person: person, contribution_formula: pack10_plan, sessions_remaining: 5, expires_at: nil) }
      let!(:consumed_book) { create(:contribution, :consumed, person: person, contribution_formula: pack10_plan, sessions_remaining: 0, expires_at: nil) }
      let!(:expired_book) { create(:contribution, :expired, person: person, contribution_formula: day_plan, expires_at: 1.week.ago) }

      it 'returns books that can be used' do
        usable = Contribution.usable
        expect(usable).to include(usable_book)
        expect(usable).not_to include(consumed_book, expired_book)
      end

      it 'excludes books with no sessions remaining' do
        used_book = create(:contribution, :active, person: person, contribution_formula: pack10_plan,
                                                   sessions_remaining: 0, expires_at: nil)
        expect(Contribution.usable).not_to include(used_book)
      end
    end
  end

  describe '#suspend!' do
    let(:circus_person) { create(:person, :with_circus_membership) }
    let(:book) { create(:contribution, person: circus_person, contribution_formula: pack10_plan, sessions_remaining: 5) }

    it 'changes status to suspended' do
      expect do
        book.suspend!(reason: 'Upgrade to trimester')
      end.to change { book.reload.status }.to('suspended')
    end

    it 'sets suspended_at timestamp' do
      expect do
        book.suspend!(reason: 'Upgrade to trimester')
      end.to change { book.reload.suspended_at }.from(nil)
      expect(book.suspended_at).to be_within(1.second).of(Time.current)
    end

    it 'sets suspended_reason' do
      book.suspend!(reason: 'Upgrade to trimester')
      expect(book.reload.suspended_reason).to eq('Upgrade to trimester')
    end

    it 'does not change sessions_remaining' do
      expect do
        book.suspend!(reason: 'Upgrade to trimester')
      end.not_to(change { book.reload.sessions_remaining })
    end
  end

  describe '#reactivate!' do
    let(:circus_person) { create(:person, :with_circus_membership) }
    let(:book) do
      create(:contribution, person: circus_person, contribution_formula: pack10_plan,
                            status: :suspended, sessions_remaining: 5, suspended_at: 1.day.ago,
                            suspended_reason: 'Upgrade to trimester')
    end

    it 'changes status from suspended to active' do
      expect do
        book.reactivate!
      end.to change { book.reload.status }.from('suspended').to('active')
    end

    it 'clears suspended_at' do
      expect do
        book.reactivate!
      end.to change { book.reload.suspended_at }.to(nil)
    end

    it 'clears suspended_reason' do
      expect do
        book.reactivate!
      end.to change { book.reload.suspended_reason }.to(nil)
    end

    it 'does nothing if book is not suspended' do
      book.update!(status: :active, suspended_at: nil, suspended_reason: nil)
      expect do
        book.reactivate!
      end.not_to(change { book.reload.status })
    end
  end

  describe '#suspended?' do
    it 'returns true when status is suspended' do
      book = create(:contribution, person: person, contribution_formula: pack10_plan, status: :suspended)
      expect(book.suspended?).to be true
    end

    it 'returns false when status is not suspended' do
      book = create(:contribution, person: person, contribution_formula: pack10_plan, status: :active)
      expect(book.suspended?).to be false
    end
  end

  describe '.suspended scope' do
    let!(:active_book) { create(:contribution, :active, person: person, contribution_formula: pack10_plan) }
    let!(:suspended_book) { create(:contribution, :suspended, person: person, contribution_formula: pack10_plan) }
    let!(:consumed_book) { create(:contribution, :consumed, person: person, contribution_formula: pack10_plan) }

    it 'returns only suspended books' do
      expect(Contribution.suspended).to include(suspended_book)
      expect(Contribution.suspended).not_to include(active_book, consumed_book)
    end
  end

  describe '.reactivate_suspended_packs_for_person' do
    let(:circus_person) { create(:person, :with_circus_membership) }
    let(:trimester_plan) { create(:contribution_formula, :trimester) }

    context 'when person has no active non-pack10 plans' do
      let!(:pack10) do
        create(:contribution, person: circus_person, contribution_formula: pack10_plan,
                              status: :suspended, sessions_remaining: 5)
      end

      it 'reactivates suspended pack10 books' do
        expect do
          Contribution.reactivate_suspended_packs_for_person(circus_person)
        end.to change { pack10.reload.status }.from('suspended').to('active')
      end
    end

    context 'when person has active trimester plan' do
      let!(:trimester_book) do
        create(:contribution, person: circus_person, contribution_formula: trimester_plan,
                              status: :active, expires_at: 1.month.from_now, sessions_remaining: nil)
      end
      let!(:pack10) do
        create(:contribution, person: circus_person, contribution_formula: pack10_plan,
                              status: :suspended, sessions_remaining: 5)
      end

      it 'does not reactivate suspended pack10 books' do
        expect do
          Contribution.reactivate_suspended_packs_for_person(circus_person)
        end.not_to(change { pack10.reload.status })
      end
    end

    context 'when person has basic membership' do
      let(:basic_person) { create(:person, :with_basic_membership) }
      let!(:pack10) do
        create(:contribution, person: basic_person, contribution_formula: pack10_plan,
                              status: :suspended, sessions_remaining: 5)
      end

      it 'does not reactivate suspended pack10 books' do
        expect do
          Contribution.reactivate_suspended_packs_for_person(basic_person)
        end.not_to(change { pack10.reload.status })
      end
    end

    context 'when multiple pack10 books exist' do
      let!(:pack10_1) do
        create(:contribution, person: circus_person, contribution_formula: pack10_plan,
                              status: :suspended, sessions_remaining: 3)
      end
      let!(:pack10_2) do
        create(:contribution, person: circus_person, contribution_formula: pack10_plan,
                              status: :suspended, sessions_remaining: 7)
      end
      let!(:pack10_active) do
        create(:contribution, person: circus_person, contribution_formula: pack10_plan,
                              status: :active, sessions_remaining: 5)
      end

      it 'reactivates all suspended pack10 books' do
        expect do
          Contribution.reactivate_suspended_packs_for_person(circus_person)
        end.to change { pack10_1.reload.status }.from('suspended').to('active')
                                                .and change { pack10_2.reload.status }.from('suspended').to('active')
      end

      it 'does not change already active pack10 books' do
        expect do
          Contribution.reactivate_suspended_packs_for_person(circus_person)
        end.not_to(change { pack10_active.reload.status })
      end
    end
  end
end
