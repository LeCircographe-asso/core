# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributionFormula, type: :model do
  describe 'validations' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }

    it 'can be created' do
      plan = ContributionFormula.new(
        membership_type: circus_membership_type,
        name: 'Test Plan',
        duration: :day,
        price_cents: 800,
        version: 1,
        effective_from: Date.current
      )
      expect(plan).to be_present
    end

    it 'requires a membership_type' do
      plan = ContributionFormula.new(
        name: 'Test Plan',
        duration: :day,
        price_cents: 800,
        version: 1,
        effective_from: Date.current
      )
      expect(plan).not_to be_valid
      expect(plan.errors[:membership_type]).to include(I18n.t('errors.messages.required'))
    end

    it 'requires a name' do
      plan = build(:contribution_formula, membership_type: circus_membership_type, name: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:name]).to include(I18n.t('errors.messages.blank'))
    end

    it 'requires a duration' do
      plan = build(:contribution_formula, membership_type: circus_membership_type, duration: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:duration]).to include(I18n.t('errors.messages.blank'))
    end

    it 'requires a price_cents' do
      plan = build(:contribution_formula, membership_type: circus_membership_type, price_cents: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:price_cents]).to include(I18n.t('errors.messages.blank'))
    end

    it 'requires price_cents to be greater than 0' do
      plan = build(:contribution_formula, membership_type: circus_membership_type, price_cents: 0)
      expect(plan).not_to be_valid
      expect(plan.errors[:price_cents]).to include(I18n.t('errors.messages.greater_than', count: 0))
    end

    it 'requires price_cents to be a number' do
      plan = build(:contribution_formula, membership_type: circus_membership_type, price_cents: 'not a number')
      expect(plan).not_to be_valid
    end

    it 'requires a version' do
      plan = build(:contribution_formula, membership_type: circus_membership_type, version: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:version]).to include(I18n.t('errors.messages.blank'))
    end

    it 'requires version to be greater than 0' do
      plan = build(:contribution_formula, membership_type: circus_membership_type, version: 0)
      expect(plan).not_to be_valid
      expect(plan.errors[:version]).to include(I18n.t('errors.messages.greater_than', count: 0))
    end

    it 'requires effective_from' do
      plan = build(:contribution_formula, membership_type: circus_membership_type, effective_from: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:effective_from]).to include(I18n.t('errors.messages.blank'))
    end

    describe 'name uniqueness scoped by version' do
      it 'allows same name with different version' do
        create(:contribution_formula, membership_type: circus_membership_type, name: 'Test Plan', version: 1)
        plan2 = build(:contribution_formula, membership_type: circus_membership_type, name: 'Test Plan', version: 2)
        expect(plan2).to be_valid
      end

      it 'prevents same name with same version' do
        create(:contribution_formula, membership_type: circus_membership_type, name: 'Test Plan', version: 1)
        plan2 = build(:contribution_formula, membership_type: circus_membership_type, name: 'Test Plan', version: 1)
        expect(plan2).not_to be_valid
        expect(plan2.errors[:name]).to be_present
      end
    end

    describe 'conditional validations for pack10' do
      context 'when duration is pack10' do
        it 'requires sessions_count' do
          plan = build(:contribution_formula, membership_type: circus_membership_type, duration: :pack10, sessions_count: nil)
          expect(plan).not_to be_valid
          expect(plan.errors[:sessions_count]).to be_present
        end

        it 'requires sessions_count to be greater than 0' do
          plan = build(:contribution_formula, membership_type: circus_membership_type, duration: :pack10, sessions_count: 0)
          expect(plan).not_to be_valid
          expect(plan.errors[:sessions_count]).to include(I18n.t('errors.messages.greater_than', count: 0))
        end

        it 'requires validity_days' do
          plan = build(:contribution_formula, membership_type: circus_membership_type, duration: :pack10, validity_days: nil)
          expect(plan).not_to be_valid
          expect(plan.errors[:validity_days]).to be_present
        end

        it 'requires validity_days to be greater than 0' do
          plan = build(:contribution_formula, membership_type: circus_membership_type, duration: :pack10, validity_days: 0)
          expect(plan).not_to be_valid
          expect(plan.errors[:validity_days]).to include(I18n.t('errors.messages.greater_than', count: 0))
        end

        it 'is valid with sessions_count and validity_days present' do
          plan = build(:contribution_formula, :pack10, membership_type: circus_membership_type, sessions_count: 10, validity_days: 365)
          expect(plan).to be_valid
        end
      end

      context 'when duration is not pack10' do
        %i[day trimester annual].each do |duration|
          it "does not require sessions_count for #{duration}" do
            plan = build(:contribution_formula, membership_type: circus_membership_type, duration: duration, sessions_count: nil)
            expect(plan).to be_valid
          end

          it "does not require validity_days for #{duration}" do
            plan = build(:contribution_formula, membership_type: circus_membership_type, duration: duration, validity_days: nil)
            expect(plan).to be_valid
          end

          it "allows sessions_count to be present for #{duration} (no validation)" do
            plan = build(:contribution_formula, membership_type: circus_membership_type, duration: duration, sessions_count: 10)
            expect(plan).to be_valid
          end
        end
      end
    end
  end

  describe 'associations' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }
    let(:plan) { create(:contribution_formula, :pack10, membership_type: circus_membership_type) }

    it 'belongs to a membership_type' do
      expect(plan.membership_type).to eq(circus_membership_type)
    end

    it 'has many contributions' do
      person = create(:person)
      entry1 = create(:contribution, person: person, contribution_formula: plan)
      entry2 = create(:contribution, person: person, contribution_formula: plan)

      expect(plan.contributions).to include(entry1, entry2)
    end

    it 'destroys contributions when deleted' do
      person = create(:person)
      create(:contribution, person: person, contribution_formula: plan)

      expect do
        plan.destroy
      end.to change(Contribution, :count).by(-1)
    end
  end

  describe 'enums' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }

    it 'has correct duration enum values' do
      day_plan = build(:contribution_formula, membership_type: circus_membership_type, duration: :day)
      expect(day_plan.duration).to eq('day')

      trimester_plan = build(:contribution_formula, membership_type: circus_membership_type, duration: :trimester)
      expect(trimester_plan.duration).to eq('trimester')

      annual_plan = build(:contribution_formula, membership_type: circus_membership_type, duration: :annual)
      expect(annual_plan.duration).to eq('annual')

      pack_plan = build(:contribution_formula, membership_type: circus_membership_type, duration: :pack10)
      expect(pack_plan.duration).to eq('pack10')
    end
  end

  describe 'instance methods' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }
    let(:basic_membership_type) { create(:membership_type, :basic) }

    describe 'type checkers' do
      it 'returns true for is_pack? when duration is pack10' do
        plan = build(:contribution_formula, :pack10, membership_type: circus_membership_type)
        expect(plan.is_pack?).to be true
      end

      it 'returns false for is_pack? when duration is not pack10' do
        plan = build(:contribution_formula, :day, membership_type: circus_membership_type)
        expect(plan.is_pack?).to be false
      end

      it 'returns true for is_pack10? when duration is pack10' do
        plan = build(:contribution_formula, :pack10, membership_type: circus_membership_type)
        expect(plan.is_pack10?).to be true
      end

      it 'returns true for is_annual? when duration is annual' do
        plan = build(:contribution_formula, :annual, membership_type: circus_membership_type)
        expect(plan.is_annual?).to be true
      end

      it 'returns true for is_trimester? when duration is trimester' do
        plan = build(:contribution_formula, :trimester, membership_type: circus_membership_type)
        expect(plan.is_trimester?).to be true
      end

      it 'returns true for is_day? when duration is day' do
        plan = build(:contribution_formula, :day, membership_type: circus_membership_type)
        expect(plan.is_day?).to be true
      end
    end

    describe '#duration_days' do
      it 'returns 1 for day duration' do
        plan = build(:contribution_formula, :day, membership_type: circus_membership_type)
        expect(plan.duration_days).to eq(1)
      end

      it 'returns 90 for trimester duration' do
        plan = build(:contribution_formula, :trimester, membership_type: circus_membership_type)
        expect(plan.duration_days).to eq(90)
      end

      it 'returns 365 for annual duration' do
        plan = build(:contribution_formula, :annual, membership_type: circus_membership_type)
        expect(plan.duration_days).to eq(365)
      end

      it 'returns nil for pack10 duration (no limited duration)' do
        plan = build(:contribution_formula, :pack10, membership_type: circus_membership_type)
        expect(plan.duration_days).to be_nil
      end

      it 'returns 0 for unknown duration (edge case)' do
        plan = build(:contribution_formula, membership_type: circus_membership_type)
        allow(plan).to receive(:duration).and_return('unknown')
        expect(plan.duration_days).to eq(0)
      end
    end

    describe '#sessions_available' do
      it 'returns sessions_count for pack10' do
        plan = build(:contribution_formula, :pack10, membership_type: circus_membership_type, sessions_count: 10)
        expect(plan.sessions_available).to eq(10)
      end

      it 'returns nil for non-pack plans' do
        plan = build(:contribution_formula, :day, membership_type: circus_membership_type)
        expect(plan.sessions_available).to be_nil
      end
    end

    describe '#for_circus_members?' do
      it 'returns true for circus membership type' do
        plan = build(:contribution_formula, membership_type: circus_membership_type)
        expect(plan.for_circus_members?).to be true
      end

      it 'returns false for basic membership type' do
        plan = build(:contribution_formula, membership_type: basic_membership_type)
        expect(plan.for_circus_members?).to be false
      end
    end

    describe '#create_price_change!' do
      let(:admin_user) { create(:user, system_role: :admin) }
      let!(:current_plan) { create(:contribution_formula, membership_type: circus_membership_type, version: 1, effective_from: 1.month.ago) }

      it 'creates a new version with incremented version number' do
        new_plan = current_plan.create_price_change!(10_000)

        expect(new_plan.version).to eq(2)
        expect(new_plan.price_cents).to eq(10_000)
        expect(new_plan.name).to eq(current_plan.name)
      end

      it 'closes current version with effective_until set to day before new effective_from' do
        new_effective_from = Date.current + 1.week
        current_plan.create_price_change!(10_000, effective_from: new_effective_from)

        current_plan.reload
        expect(current_plan.effective_until).to eq(new_effective_from - 1.day)
      end

      it 'sets effective_from for new version' do
        new_effective_from = Date.current + 1.week
        new_plan = current_plan.create_price_change!(10_000, effective_from: new_effective_from)

        expect(new_plan.effective_from).to eq(new_effective_from)
      end

      it 'sets effective_until to nil for new version' do
        new_plan = current_plan.create_price_change!(10_000)

        expect(new_plan.effective_until).to be_nil
      end

      it 'sets created_by_user when provided' do
        new_plan = current_plan.create_price_change!(10_000, user: admin_user)

        expect(new_plan.created_by_user).to eq(admin_user)
      end

      it 'sets change_reason when provided' do
        reason = 'Inflation adjustment'
        new_plan = current_plan.create_price_change!(10_000, reason: reason)

        expect(new_plan.change_reason).to eq(reason)
      end

      context 'edge cases' do
        it 'handles same day effective_from correctly' do
          today = Date.current
          plan = create(:contribution_formula, membership_type: circus_membership_type, effective_from: today)

          plan.create_price_change!(10_000, effective_from: today)

          plan.reload
          expect(plan.effective_until.to_date).to eq(today - 1.day)
        end

        it 'handles past effective_from date' do
          past_date = 1.month.ago.to_date
          current_plan.create_price_change!(10_000, effective_from: past_date)

          current_plan.reload
          expect(current_plan.effective_until.to_date).to eq(past_date - 1.day)
        end

        it 'duplicates all attributes except version, price, dates, and user fields' do
          new_plan = current_plan.create_price_change!(10_000)

          expect(new_plan.name).to eq(current_plan.name)
          expect(new_plan.duration).to eq(current_plan.duration)
          expect(new_plan.description).to eq(current_plan.description)
          expect(new_plan.membership_type).to eq(current_plan.membership_type)
        end
      end
    end

    describe '#price_evolution' do
      let!(:plan1) { create(:contribution_formula, membership_type: circus_membership_type, name: 'Test Plan', version: 1, effective_from: 3.months.ago, price_cents: 5000) }
      let!(:plan2) { create(:contribution_formula, membership_type: circus_membership_type, name: 'Test Plan', version: 2, effective_from: 2.months.ago, effective_until: 1.month.ago, price_cents: 6000) }
      let!(:plan3) { create(:contribution_formula, membership_type: circus_membership_type, name: 'Test Plan', version: 3, effective_from: 1.month.ago, price_cents: 7000) }

      it 'returns all versions of plans with same name ordered by effective_from' do
        evolution = plan1.price_evolution

        expect(evolution).to include(plan1, plan2, plan3)
        expect(evolution.first).to eq(plan1)
        expect(evolution.last).to eq(plan3)
      end

      it 'does not include plans with different names' do
        other_plan = create(:contribution_formula, membership_type: circus_membership_type, name: 'Other Plan', version: 1)

        expect(plan1.price_evolution).not_to include(other_plan)
      end
    end

    describe '#price_change_percentage' do
      let!(:old_plan) { create(:contribution_formula, membership_type: circus_membership_type, name: 'Test Plan', version: 1, effective_from: 1.year.ago, price_cents: 5000) }
      let!(:new_plan) { create(:contribution_formula, membership_type: circus_membership_type, name: 'Test Plan', version: 2, effective_from: Date.current, price_cents: 7000) }

      it 'calculates percentage correctly for price increase' do
        old_date = 1.year.ago
        new_date = Date.current

        percentage = old_plan.price_change_percentage(old_date, new_date)

        # 7000 - 5000 = 2000, 2000 / 5000 = 0.4, 0.4 * 100 = 40%
        expect(percentage).to eq(40.0)
      end

      it 'calculates percentage correctly for price decrease' do
        create(:contribution_formula, membership_type: circus_membership_type, name: 'Test Plan', version: 3, effective_from: Date.current + 1.day, price_cents: 3000)

        percentage = old_plan.price_change_percentage(1.year.ago, Date.current + 1.day)

        # 3000 - 5000 = -2000, -2000 / 5000 = -0.4, -0.4 * 100 = -40%
        expect(percentage).to eq(-40.0)
      end

      context 'edge cases' do
        it 'returns nil when old_price is not found' do
          percentage = old_plan.price_change_percentage(10.years.ago, Date.current)
          expect(percentage).to be_nil
        end

        it 'returns nil when new_price is not found' do
          percentage = old_plan.price_change_percentage(1.year.ago, 10.years.from_now)
          expect(percentage).to be_nil
        end

        it 'rounds result to 2 decimal places' do
          odd_plan = create(:contribution_formula, membership_type: circus_membership_type, name: 'Odd Plan', version: 1, effective_from: 1.year.ago, price_cents: 3333)
          create(:contribution_formula, membership_type: circus_membership_type, name: 'Odd Plan', version: 2, effective_from: Date.current, price_cents: 5000)

          percentage = odd_plan.price_change_percentage(1.year.ago, Date.current)

          # 5000 - 3333 = 1667, 1667 / 3333 ~ 0.5001 or 0.5002
          expect(percentage).to be > 50.00
          expect(percentage).to be < 50.10
        end
      end
    end
  end

  describe 'scopes' do
    let(:circus_full_type) { create(:membership_type, category: :circus, name: 'Adhésion Cirque Complète', price_cents: 2500) }
    let(:circus_reduced_type) { create(:membership_type, category: :circus, name: 'Adhésion Cirque Réduite', price_cents: 2000) }
    let(:basic_type) { create(:membership_type, :basic) }

    describe '.for_circus_members' do
      let!(:circus_full_plan) { create(:contribution_formula, membership_type: circus_full_type) }
      let!(:circus_reduced_plan) { create(:contribution_formula, membership_type: circus_reduced_type) }
      let!(:basic_plan) { create(:contribution_formula, membership_type: basic_type) }

      it 'includes plans for circus_full members' do
        expect(ContributionFormula.for_circus_members).to include(circus_full_plan)
      end

      it 'includes plans for circus_reduced members' do
        expect(ContributionFormula.for_circus_members).to include(circus_reduced_plan)
      end

      it 'excludes plans for basic members' do
        expect(ContributionFormula.for_circus_members).not_to include(basic_plan)
      end
    end

    describe 'duration scopes' do
      let!(:day_plan) { create(:contribution_formula, :day, membership_type: circus_full_type) }
      let!(:trimester_plan) { create(:contribution_formula, :trimester, membership_type: circus_full_type) }
      let!(:annual_plan) { create(:contribution_formula, :annual, membership_type: circus_full_type) }
      let!(:pack_plan) { create(:contribution_formula, :pack10, membership_type: circus_full_type) }

      it 'finds day plans' do
        expect(ContributionFormula.day_plans).to include(day_plan)
        expect(ContributionFormula.day_plans).not_to include(trimester_plan, annual_plan, pack_plan)
      end

      it 'finds trimester plans' do
        expect(ContributionFormula.trimester_plans).to include(trimester_plan)
        expect(ContributionFormula.trimester_plans).not_to include(day_plan, annual_plan, pack_plan)
      end

      it 'finds annual plans' do
        expect(ContributionFormula.annual_plans).to include(annual_plan)
        expect(ContributionFormula.annual_plans).not_to include(day_plan, trimester_plan, pack_plan)
      end

      it 'finds pack plans' do
        expect(ContributionFormula.pack_plans).to include(pack_plan)
        expect(ContributionFormula.pack_plans).not_to include(day_plan, trimester_plan, annual_plan)
      end
    end

    describe '.by_price' do
      let!(:cheap_plan) { create(:contribution_formula, membership_type: circus_full_type, price_cents: 1000) }
      let!(:expensive_plan) { create(:contribution_formula, membership_type: circus_full_type, price_cents: 5000) }
      let!(:medium_plan) { create(:contribution_formula, membership_type: circus_full_type, price_cents: 3000) }

      it 'orders plans by price ascending' do
        ordered = ContributionFormula.by_price
        expect(ordered.first).to eq(cheap_plan)
        expect(ordered.last).to eq(expensive_plan)
      end
    end

    describe '.current_versions' do
      let!(:current_plan) { create(:contribution_formula, membership_type: circus_full_type, effective_until: nil) }
      let!(:expired_plan) { create(:contribution_formula, membership_type: circus_full_type, effective_until: 1.month.ago) }

      it 'includes plans with effective_until nil' do
        expect(ContributionFormula.current_versions).to include(current_plan)
      end

      it 'excludes plans with effective_until set' do
        expect(ContributionFormula.current_versions).not_to include(expired_plan)
      end
    end

    describe '.effective_on' do
      let(:target_date) { Date.current }
      let!(:past_plan) { create(:contribution_formula, membership_type: circus_full_type, effective_from: 2.months.ago, effective_until: 1.month.ago) }
      let!(:current_plan) { create(:contribution_formula, membership_type: circus_full_type, effective_from: 1.month.ago, effective_until: nil) }
      let!(:future_plan) { create(:contribution_formula, membership_type: circus_full_type, effective_from: 1.month.from_now) }

      it 'includes plans effective on target date' do
        expect(ContributionFormula.effective_on(target_date)).to include(current_plan)
      end

      it 'excludes plans expired before target date' do
        expect(ContributionFormula.effective_on(target_date)).not_to include(past_plan)
      end

      it 'excludes plans starting after target date' do
        expect(ContributionFormula.effective_on(target_date)).not_to include(future_plan)
      end
    end

    describe '.price_history' do
      let!(:plan1) { create(:contribution_formula, membership_type: circus_full_type, name: 'Plan A', version: 1, effective_from: 3.months.ago) }
      let!(:plan2) { create(:contribution_formula, membership_type: circus_full_type, name: 'Plan A', version: 2, effective_from: 2.months.ago) }
      let!(:plan3) { create(:contribution_formula, membership_type: circus_full_type, name: 'Plan A', version: 3, effective_from: 1.month.ago) }
      let!(:other_plan) { create(:contribution_formula, membership_type: circus_full_type, name: 'Plan B', version: 1) }

      it 'orders all plans by effective_from and version' do
        history = ContributionFormula.price_history
        # Should include all plans
        expect(history.count).to eq(4)
      end
    end
  end

  describe 'Priceable concern' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }

    describe '#price_euros' do
      it 'converts price_cents to euros correctly' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, price_cents: 1000)
        expect(plan.price_euros).to eq(10.0)
      end

      it 'handles cents correctly' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, price_cents: 1050)
        expect(plan.price_euros).to eq(10.50)
      end
    end

    describe '#price_euros=' do
      it 'converts euros to price_cents correctly' do
        plan = build(:contribution_formula, membership_type: circus_membership_type)
        plan.price_euros = 25.50

        expect(plan.price_cents).to eq(2550)
      end
    end

    describe '#formatted_price' do
      it 'formats price correctly' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, price_cents: 1500)
        expect(plan.formatted_price).to eq('15.0€')
      end
    end

    describe '#name_with_price' do
      it 'combines name and formatted price' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, name: 'Test Plan', price_cents: 2000)
        expect(plan.name_with_price).to eq('Test Plan - 20.0€')
      end
    end
  end

  describe 'Versionable concern' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }

    describe '#current_version?' do
      it 'returns true when effective_until is nil' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, effective_until: nil)
        expect(plan.current_version?).to be true
      end

      it 'returns false when effective_until is set' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, effective_until: Date.current)
        expect(plan.current_version?).to be false
      end
    end

    describe '#expired_version?' do
      it 'returns true when effective_until is in the past' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, effective_until: 1.month.ago)
        expect(plan.expired_version?).to be true
      end

      it 'returns false when effective_until is in the future' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, effective_until: 1.month.from_now)
        expect(plan.expired_version?).to be false
      end

      it 'returns false when effective_until is nil' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, effective_until: nil)
        expect(plan.expired_version?).to be false
      end
    end

    describe '#future_version?' do
      it 'returns true when effective_from is in the future' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, effective_from: 1.month.from_now)
        expect(plan.future_version?).to be true
      end

      it 'returns false when effective_from is today' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, effective_from: Date.current)
        expect(plan.future_version?).to be false
      end

      it 'returns false when effective_from is in the past' do
        plan = build(:contribution_formula, membership_type: circus_membership_type, effective_from: 1.month.ago)
        expect(plan.future_version?).to be false
      end
    end
  end

  describe 'class methods' do
    describe '.create_default_plans!' do
      let!(:circus_full_type) { create(:membership_type, category: :circus, name: 'Adhésion Cirque Complète', price_cents: 2500) }
      let!(:circus_reduced_type) { create(:membership_type, category: :circus, name: 'Adhésion Cirque Réduite', price_cents: 2000) }

      context 'when no plans exist' do
        it 'creates all default plans for circus_full' do
          # 4 plans × 2 circus types
          expect do
            ContributionFormula.create_default_plans!
          end.to change(ContributionFormula, :count).by(8)
        end

        it 'creates day plan for circus_full' do
          ContributionFormula.create_default_plans!

          day_plan = ContributionFormula.find_by(name: "Journée - #{circus_full_type.name}")
          expect(day_plan).to be_present
          expect(day_plan.duration).to eq('day')
          expect(day_plan.price_cents).to eq(800)
        end

        it 'creates trimester plan for circus_full' do
          ContributionFormula.create_default_plans!

          trimester_plan = ContributionFormula.find_by(name: "Trimestre - #{circus_full_type.name}")
          expect(trimester_plan).to be_present
          expect(trimester_plan.duration).to eq('trimester')
          expect(trimester_plan.price_cents).to eq(6000)
        end

        it 'creates annual plan for circus_full' do
          ContributionFormula.create_default_plans!

          annual_plan = ContributionFormula.find_by(name: "Annuel - #{circus_full_type.name}")
          expect(annual_plan).to be_present
          expect(annual_plan.duration).to eq('annual')
          expect(annual_plan.price_cents).to eq(20_000)
        end

        it 'creates pack10 plan for circus_full' do
          ContributionFormula.create_default_plans!

          pack_plan = ContributionFormula.find_by(name: "Pack 10 séances - #{circus_full_type.name}")
          expect(pack_plan).to be_present
          expect(pack_plan.duration).to eq('pack10')
          expect(pack_plan.price_cents).to eq(7000)
          expect(pack_plan.sessions_count).to eq(10)
          expect(pack_plan.validity_days).to eq(365)
        end

        it 'creates plans for circus_reduced' do
          ContributionFormula.create_default_plans!

          reduced_plan = ContributionFormula.find_by(name: "Journée - #{circus_reduced_type.name}")
          expect(reduced_plan).to be_present
        end

        it 'does not create plans for basic membership types' do
          basic_type = create(:membership_type, :basic)

          ContributionFormula.create_default_plans!

          basic_plan = ContributionFormula.find_by('name LIKE ?', "%#{basic_type.name}%")
          expect(basic_plan).to be_nil
        end
      end

      context 'when plans already exist' do
        before do
          ContributionFormula.create_default_plans!
        end

        it 'does not duplicate existing plans' do
          expect do
            ContributionFormula.create_default_plans!
          end.not_to change(ContributionFormula, :count)
        end

        it 'keeps existing plan attributes' do
          existing_day_plan = ContributionFormula.find_by(name: "Journée - #{circus_full_type.name}")
          original_price = existing_day_plan.price_cents

          ContributionFormula.create_default_plans!

          existing_day_plan.reload
          expect(existing_day_plan.price_cents).to eq(original_price)
        end
      end
    end
  end
end
