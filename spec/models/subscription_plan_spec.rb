require 'rails_helper'

RSpec.describe SubscriptionPlan, type: :model do
  describe 'validations' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }

    it "can be created" do
      plan = SubscriptionPlan.new(
        membership_type: circus_membership_type,
        name: "Test Plan",
        duration: :day,
        price_cents: 800,
        version: 1,
        effective_from: Date.current
      )
      expect(plan).to be_present
    end

    it "requires a membership_type" do
      plan = SubscriptionPlan.new(
        name: "Test Plan",
        duration: :day,
        price_cents: 800,
        version: 1,
        effective_from: Date.current
      )
      expect(plan).not_to be_valid
      expect(plan.errors[:membership_type]).to include("must exist")
    end

    it "requires a name" do
      plan = build(:subscription_plan, membership_type: circus_membership_type, name: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:name]).to include("can't be blank")
    end

    it "requires a duration" do
      plan = build(:subscription_plan, membership_type: circus_membership_type, duration: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:duration]).to include("can't be blank")
    end

    it "requires a price_cents" do
      plan = build(:subscription_plan, membership_type: circus_membership_type, price_cents: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:price_cents]).to include("can't be blank")
    end

    it "requires price_cents to be greater than 0" do
      plan = build(:subscription_plan, membership_type: circus_membership_type, price_cents: 0)
      expect(plan).not_to be_valid
      expect(plan.errors[:price_cents]).to include("must be greater than 0")
    end

    it "requires price_cents to be a number" do
      plan = build(:subscription_plan, membership_type: circus_membership_type, price_cents: "not a number")
      expect(plan).not_to be_valid
    end

    it "requires a version" do
      plan = build(:subscription_plan, membership_type: circus_membership_type, version: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:version]).to include("can't be blank")
    end

    it "requires version to be greater than 0" do
      plan = build(:subscription_plan, membership_type: circus_membership_type, version: 0)
      expect(plan).not_to be_valid
      expect(plan.errors[:version]).to include("must be greater than 0")
    end

    it "requires effective_from" do
      plan = build(:subscription_plan, membership_type: circus_membership_type, effective_from: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:effective_from]).to include("can't be blank")
    end

    describe 'name uniqueness scoped by version' do
      it "allows same name with different version" do
        create(:subscription_plan, membership_type: circus_membership_type, name: "Test Plan", version: 1)
        plan2 = build(:subscription_plan, membership_type: circus_membership_type, name: "Test Plan", version: 2)
        expect(plan2).to be_valid
      end

      it "prevents same name with same version" do
        create(:subscription_plan, membership_type: circus_membership_type, name: "Test Plan", version: 1)
        plan2 = build(:subscription_plan, membership_type: circus_membership_type, name: "Test Plan", version: 1)
        expect(plan2).not_to be_valid
        expect(plan2.errors[:name]).to be_present
      end
    end

    describe 'conditional validations for pack10' do
      context 'when duration is pack10' do
        it "requires sessions_count" do
          plan = build(:subscription_plan, membership_type: circus_membership_type, duration: :pack10, sessions_count: nil)
          expect(plan).not_to be_valid
          expect(plan.errors[:sessions_count]).to be_present
        end

        it "requires sessions_count to be greater than 0" do
          plan = build(:subscription_plan, membership_type: circus_membership_type, duration: :pack10, sessions_count: 0)
          expect(plan).not_to be_valid
          expect(plan.errors[:sessions_count]).to include("must be greater than 0")
        end

        it "requires validity_days" do
          plan = build(:subscription_plan, membership_type: circus_membership_type, duration: :pack10, validity_days: nil)
          expect(plan).not_to be_valid
          expect(plan.errors[:validity_days]).to be_present
        end

        it "requires validity_days to be greater than 0" do
          plan = build(:subscription_plan, membership_type: circus_membership_type, duration: :pack10, validity_days: 0)
          expect(plan).not_to be_valid
          expect(plan.errors[:validity_days]).to include("must be greater than 0")
        end

        it "is valid with sessions_count and validity_days present" do
          plan = build(:subscription_plan, :pack10, membership_type: circus_membership_type, sessions_count: 10, validity_days: 365)
          expect(plan).to be_valid
        end
      end

      context 'when duration is not pack10' do
        [:day, :trimester, :annual].each do |duration|
          it "does not require sessions_count for #{duration}" do
            plan = build(:subscription_plan, membership_type: circus_membership_type, duration: duration, sessions_count: nil)
            expect(plan).to be_valid
          end

          it "does not require validity_days for #{duration}" do
            plan = build(:subscription_plan, membership_type: circus_membership_type, duration: duration, validity_days: nil)
            expect(plan).to be_valid
          end

          it "allows sessions_count to be present for #{duration} (no validation)" do
            plan = build(:subscription_plan, membership_type: circus_membership_type, duration: duration, sessions_count: 10)
            expect(plan).to be_valid
          end
        end
      end
    end
  end

  describe 'associations' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }
    let(:plan) { create(:subscription_plan, :pack10, membership_type: circus_membership_type) }

    it "belongs to a membership_type" do
      expect(plan.membership_type).to eq(circus_membership_type)
    end

    it "has many book_of_entries" do
      person = create(:person)
      entry1 = create(:book_of_entry, person: person, subscription_plan: plan)
      entry2 = create(:book_of_entry, person: person, subscription_plan: plan)
      
      expect(plan.book_of_entries).to include(entry1, entry2)
    end

    it "destroys book_of_entries when deleted" do
      person = create(:person)
      entry = create(:book_of_entry, person: person, subscription_plan: plan)
      
      expect {
        plan.destroy
      }.to change(BookOfEntry, :count).by(-1)
    end
  end

  describe 'enums' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }

    it "has correct duration enum values" do
      day_plan = build(:subscription_plan, membership_type: circus_membership_type, duration: :day)
      expect(day_plan.duration).to eq("day")
      
      trimester_plan = build(:subscription_plan, membership_type: circus_membership_type, duration: :trimester)
      expect(trimester_plan.duration).to eq("trimester")
      
      annual_plan = build(:subscription_plan, membership_type: circus_membership_type, duration: :annual)
      expect(annual_plan.duration).to eq("annual")
      
      pack_plan = build(:subscription_plan, membership_type: circus_membership_type, duration: :pack10)
      expect(pack_plan.duration).to eq("pack10")
    end
  end

  describe 'instance methods' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }
    let(:basic_membership_type) { create(:membership_type, :basic) }

    describe 'type checkers' do
      it "returns true for is_pack? when duration is pack10" do
        plan = build(:subscription_plan, :pack10, membership_type: circus_membership_type)
        expect(plan.is_pack?).to be true
      end

      it "returns false for is_pack? when duration is not pack10" do
        plan = build(:subscription_plan, :day, membership_type: circus_membership_type)
        expect(plan.is_pack?).to be false
      end

      it "returns true for is_pack10? when duration is pack10" do
        plan = build(:subscription_plan, :pack10, membership_type: circus_membership_type)
        expect(plan.is_pack10?).to be true
      end

      it "returns true for is_annual? when duration is annual" do
        plan = build(:subscription_plan, :annual, membership_type: circus_membership_type)
        expect(plan.is_annual?).to be true
      end

      it "returns true for is_trimester? when duration is trimester" do
        plan = build(:subscription_plan, :trimester, membership_type: circus_membership_type)
        expect(plan.is_trimester?).to be true
      end

      it "returns true for is_day? when duration is day" do
        plan = build(:subscription_plan, :day, membership_type: circus_membership_type)
        expect(plan.is_day?).to be true
      end
    end

    describe '#duration_days' do
      it "returns 1 for day duration" do
        plan = build(:subscription_plan, :day, membership_type: circus_membership_type)
        expect(plan.duration_days).to eq(1)
      end

      it "returns 90 for trimester duration" do
        plan = build(:subscription_plan, :trimester, membership_type: circus_membership_type)
        expect(plan.duration_days).to eq(90)
      end

      it "returns 365 for annual duration" do
        plan = build(:subscription_plan, :annual, membership_type: circus_membership_type)
        expect(plan.duration_days).to eq(365)
      end

      it "returns nil for pack10 duration (no limited duration)" do
        plan = build(:subscription_plan, :pack10, membership_type: circus_membership_type)
        expect(plan.duration_days).to be_nil
      end

      it "returns 0 for unknown duration (edge case)" do
        plan = build(:subscription_plan, membership_type: circus_membership_type)
        allow(plan).to receive(:duration).and_return("unknown")
        expect(plan.duration_days).to eq(0)
      end
    end

    describe '#sessions_available' do
      it "returns sessions_count for pack10" do
        plan = build(:subscription_plan, :pack10, membership_type: circus_membership_type, sessions_count: 10)
        expect(plan.sessions_available).to eq(10)
      end

      it "returns nil for non-pack plans" do
        plan = build(:subscription_plan, :day, membership_type: circus_membership_type)
        expect(plan.sessions_available).to be_nil
      end
    end

    describe '#for_circus_members?' do
      it "returns true for circus membership type" do
        plan = build(:subscription_plan, membership_type: circus_membership_type)
        expect(plan.for_circus_members?).to be true
      end

      it "returns false for basic membership type" do
        plan = build(:subscription_plan, membership_type: basic_membership_type)
        expect(plan.for_circus_members?).to be false
      end
    end

    describe '#create_price_change!' do
      let(:admin_user) { create(:user, system_role: :admin) }
      let!(:current_plan) { create(:subscription_plan, membership_type: circus_membership_type, version: 1, effective_from: 1.month.ago) }

      it "creates a new version with incremented version number" do
        new_plan = current_plan.create_price_change!(10000)
        
        expect(new_plan.version).to eq(2)
        expect(new_plan.price_cents).to eq(10000)
        expect(new_plan.name).to eq(current_plan.name)
      end

      it "closes current version with effective_until set to day before new effective_from" do
        new_effective_from = Date.current + 1.week
        current_plan.create_price_change!(10000, effective_from: new_effective_from)
        
        current_plan.reload
        expect(current_plan.effective_until).to eq(new_effective_from - 1.day)
      end

      it "sets effective_from for new version" do
        new_effective_from = Date.current + 1.week
        new_plan = current_plan.create_price_change!(10000, effective_from: new_effective_from)
        
        expect(new_plan.effective_from).to eq(new_effective_from)
      end

      it "sets effective_until to nil for new version" do
        new_plan = current_plan.create_price_change!(10000)
        
        expect(new_plan.effective_until).to be_nil
      end

      it "sets created_by_user when provided" do
        new_plan = current_plan.create_price_change!(10000, user: admin_user)
        
        expect(new_plan.created_by_user).to eq(admin_user)
      end

      it "sets change_reason when provided" do
        reason = "Inflation adjustment"
        new_plan = current_plan.create_price_change!(10000, reason: reason)
        
        expect(new_plan.change_reason).to eq(reason)
      end

      context 'edge cases' do
        it "handles same day effective_from correctly" do
          today = Date.current
          plan = create(:subscription_plan, membership_type: circus_membership_type, effective_from: today)
          
          new_plan = plan.create_price_change!(10000, effective_from: today)
          
          plan.reload
          expect(plan.effective_until.to_date).to eq(today - 1.day)
        end

        it "handles past effective_from date" do
          past_date = 1.month.ago.to_date
          new_plan = current_plan.create_price_change!(10000, effective_from: past_date)
          
          current_plan.reload
          expect(current_plan.effective_until.to_date).to eq(past_date - 1.day)
        end

        it "duplicates all attributes except version, price, dates, and user fields" do
          new_plan = current_plan.create_price_change!(10000)
          
          expect(new_plan.name).to eq(current_plan.name)
          expect(new_plan.duration).to eq(current_plan.duration)
          expect(new_plan.description).to eq(current_plan.description)
          expect(new_plan.membership_type).to eq(current_plan.membership_type)
        end
      end
    end

    describe '#price_evolution' do
      let!(:plan1) { create(:subscription_plan, membership_type: circus_membership_type, name: "Test Plan", version: 1, effective_from: 3.months.ago, price_cents: 5000) }
      let!(:plan2) { create(:subscription_plan, membership_type: circus_membership_type, name: "Test Plan", version: 2, effective_from: 2.months.ago, effective_until: 1.month.ago, price_cents: 6000) }
      let!(:plan3) { create(:subscription_plan, membership_type: circus_membership_type, name: "Test Plan", version: 3, effective_from: 1.month.ago, price_cents: 7000) }

      it "returns all versions of plans with same name ordered by effective_from" do
        evolution = plan1.price_evolution
        
        expect(evolution).to include(plan1, plan2, plan3)
        expect(evolution.first).to eq(plan1)
        expect(evolution.last).to eq(plan3)
      end

      it "does not include plans with different names" do
        other_plan = create(:subscription_plan, membership_type: circus_membership_type, name: "Other Plan", version: 1)
        
        expect(plan1.price_evolution).not_to include(other_plan)
      end
    end

    describe '#price_change_percentage' do
      let!(:old_plan) { create(:subscription_plan, membership_type: circus_membership_type, name: "Test Plan", version: 1, effective_from: 1.year.ago, price_cents: 5000) }
      let!(:new_plan) { create(:subscription_plan, membership_type: circus_membership_type, name: "Test Plan", version: 2, effective_from: Date.current, price_cents: 7000) }

      it "calculates percentage correctly for price increase" do
        old_date = 1.year.ago
        new_date = Date.current
        
        percentage = old_plan.price_change_percentage(old_date, new_date)
        
        # 7000 - 5000 = 2000, 2000 / 5000 = 0.4, 0.4 * 100 = 40%
        expect(percentage).to eq(40.0)
      end

      it "calculates percentage correctly for price decrease" do
        lower_plan = create(:subscription_plan, membership_type: circus_membership_type, name: "Test Plan", version: 3, effective_from: Date.current + 1.day, price_cents: 3000)
        
        percentage = old_plan.price_change_percentage(1.year.ago, Date.current + 1.day)
        
        # 3000 - 5000 = -2000, -2000 / 5000 = -0.4, -0.4 * 100 = -40%
        expect(percentage).to eq(-40.0)
      end

      context 'edge cases' do
        it "returns nil when old_price is not found" do
          percentage = old_plan.price_change_percentage(10.years.ago, Date.current)
          expect(percentage).to be_nil
        end

        it "returns nil when new_price is not found" do
          percentage = old_plan.price_change_percentage(1.year.ago, 10.years.from_now)
          expect(percentage).to be_nil
        end

        it "rounds result to 2 decimal places" do
          odd_plan = create(:subscription_plan, membership_type: circus_membership_type, name: "Odd Plan", version: 1, effective_from: 1.year.ago, price_cents: 3333)
          other_plan = create(:subscription_plan, membership_type: circus_membership_type, name: "Odd Plan", version: 2, effective_from: Date.current, price_cents: 5000)
          
          percentage = odd_plan.price_change_percentage(1.year.ago, Date.current)
          
          # 5000 - 3333 = 1667, 1667 / 3333 ~ 0.5001 or 0.5002
          expect(percentage).to be > 50.00
          expect(percentage).to be < 50.10
        end
      end
    end
  end

  describe 'scopes' do
      let(:circus_full_type) { create(:membership_type, category: :circus, name: "Adhésion Cirque Complète", price_cents: 2500) }
      let(:circus_reduced_type) { create(:membership_type, category: :circus, name: "Adhésion Cirque Réduite", price_cents: 2000) }
    let(:basic_type) { create(:membership_type, :basic) }

    describe '.for_circus_members' do
      let!(:circus_full_plan) { create(:subscription_plan, membership_type: circus_full_type) }
      let!(:circus_reduced_plan) { create(:subscription_plan, membership_type: circus_reduced_type) }
      let!(:basic_plan) { create(:subscription_plan, membership_type: basic_type) }

      it "includes plans for circus_full members" do
        expect(SubscriptionPlan.for_circus_members).to include(circus_full_plan)
      end

      it "includes plans for circus_reduced members" do
        expect(SubscriptionPlan.for_circus_members).to include(circus_reduced_plan)
      end

      it "excludes plans for basic members" do
        expect(SubscriptionPlan.for_circus_members).not_to include(basic_plan)
      end
    end

    describe 'duration scopes' do
      let!(:day_plan) { create(:subscription_plan, :day, membership_type: circus_full_type) }
      let!(:trimester_plan) { create(:subscription_plan, :trimester, membership_type: circus_full_type) }
      let!(:annual_plan) { create(:subscription_plan, :annual, membership_type: circus_full_type) }
      let!(:pack_plan) { create(:subscription_plan, :pack10, membership_type: circus_full_type) }

      it "finds day plans" do
        expect(SubscriptionPlan.day_plans).to include(day_plan)
        expect(SubscriptionPlan.day_plans).not_to include(trimester_plan, annual_plan, pack_plan)
      end

      it "finds trimester plans" do
        expect(SubscriptionPlan.trimester_plans).to include(trimester_plan)
        expect(SubscriptionPlan.trimester_plans).not_to include(day_plan, annual_plan, pack_plan)
      end

      it "finds annual plans" do
        expect(SubscriptionPlan.annual_plans).to include(annual_plan)
        expect(SubscriptionPlan.annual_plans).not_to include(day_plan, trimester_plan, pack_plan)
      end

      it "finds pack plans" do
        expect(SubscriptionPlan.pack_plans).to include(pack_plan)
        expect(SubscriptionPlan.pack_plans).not_to include(day_plan, trimester_plan, annual_plan)
      end
    end

    describe '.by_price' do
      let!(:cheap_plan) { create(:subscription_plan, membership_type: circus_full_type, price_cents: 1000) }
      let!(:expensive_plan) { create(:subscription_plan, membership_type: circus_full_type, price_cents: 5000) }
      let!(:medium_plan) { create(:subscription_plan, membership_type: circus_full_type, price_cents: 3000) }

      it "orders plans by price ascending" do
        ordered = SubscriptionPlan.by_price
        expect(ordered.first).to eq(cheap_plan)
        expect(ordered.last).to eq(expensive_plan)
      end
    end

    describe '.current_versions' do
      let!(:current_plan) { create(:subscription_plan, membership_type: circus_full_type, effective_until: nil) }
      let!(:expired_plan) { create(:subscription_plan, membership_type: circus_full_type, effective_until: 1.month.ago) }

      it "includes plans with effective_until nil" do
        expect(SubscriptionPlan.current_versions).to include(current_plan)
      end

      it "excludes plans with effective_until set" do
        expect(SubscriptionPlan.current_versions).not_to include(expired_plan)
      end
    end

    describe '.effective_on' do
      let(:target_date) { Date.current }
      let!(:past_plan) { create(:subscription_plan, membership_type: circus_full_type, effective_from: 2.months.ago, effective_until: 1.month.ago) }
      let!(:current_plan) { create(:subscription_plan, membership_type: circus_full_type, effective_from: 1.month.ago, effective_until: nil) }
      let!(:future_plan) { create(:subscription_plan, membership_type: circus_full_type, effective_from: 1.month.from_now) }

      it "includes plans effective on target date" do
        expect(SubscriptionPlan.effective_on(target_date)).to include(current_plan)
      end

      it "excludes plans expired before target date" do
        expect(SubscriptionPlan.effective_on(target_date)).not_to include(past_plan)
      end

      it "excludes plans starting after target date" do
        expect(SubscriptionPlan.effective_on(target_date)).not_to include(future_plan)
      end
    end

    describe '.price_history' do
      let!(:plan1) { create(:subscription_plan, membership_type: circus_full_type, name: "Plan A", version: 1, effective_from: 3.months.ago) }
      let!(:plan2) { create(:subscription_plan, membership_type: circus_full_type, name: "Plan A", version: 2, effective_from: 2.months.ago) }
      let!(:plan3) { create(:subscription_plan, membership_type: circus_full_type, name: "Plan A", version: 3, effective_from: 1.month.ago) }
      let!(:other_plan) { create(:subscription_plan, membership_type: circus_full_type, name: "Plan B", version: 1) }

      it "orders all plans by effective_from and version" do
        history = SubscriptionPlan.price_history
        # Should include all plans
        expect(history.count).to eq(4)
      end
    end
  end

  describe 'Priceable concern' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }

    describe '#price_euros' do
      it "converts price_cents to euros correctly" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, price_cents: 1000)
        expect(plan.price_euros).to eq(10.0)
      end

      it "handles cents correctly" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, price_cents: 1050)
        expect(plan.price_euros).to eq(10.50)
      end
    end

    describe '#price_euros=' do
      it "converts euros to price_cents correctly" do
        plan = build(:subscription_plan, membership_type: circus_membership_type)
        plan.price_euros = 25.50
        
        expect(plan.price_cents).to eq(2550)
      end
    end

    describe '#formatted_price' do
      it "formats price correctly" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, price_cents: 1500)
        expect(plan.formatted_price).to eq("15.0€")
      end
    end

    describe '#name_with_price' do
      it "combines name and formatted price" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, name: "Test Plan", price_cents: 2000)
        expect(plan.name_with_price).to eq("Test Plan - 20.0€")
      end
    end
  end

  describe 'Versionable concern' do
    let(:circus_membership_type) { create(:membership_type, category: :circus) }

    describe '#current_version?' do
      it "returns true when effective_until is nil" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, effective_until: nil)
        expect(plan.current_version?).to be true
      end

      it "returns false when effective_until is set" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, effective_until: Date.current)
        expect(plan.current_version?).to be false
      end
    end

    describe '#expired_version?' do
      it "returns true when effective_until is in the past" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, effective_until: 1.month.ago)
        expect(plan.expired_version?).to be true
      end

      it "returns false when effective_until is in the future" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, effective_until: 1.month.from_now)
        expect(plan.expired_version?).to be false
      end

      it "returns false when effective_until is nil" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, effective_until: nil)
        expect(plan.expired_version?).to be false
      end
    end

    describe '#future_version?' do
      it "returns true when effective_from is in the future" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, effective_from: 1.month.from_now)
        expect(plan.future_version?).to be true
      end

      it "returns false when effective_from is today" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, effective_from: Date.current)
        expect(plan.future_version?).to be false
      end

      it "returns false when effective_from is in the past" do
        plan = build(:subscription_plan, membership_type: circus_membership_type, effective_from: 1.month.ago)
        expect(plan.future_version?).to be false
      end
    end
  end

  describe 'class methods' do
    describe '.create_default_plans!' do
      let!(:circus_full_type) { create(:membership_type, category: :circus, name: "Adhésion Cirque Complète", price_cents: 2500) }
      let!(:circus_reduced_type) { create(:membership_type, category: :circus, name: "Adhésion Cirque Réduite", price_cents: 2000) }

      context 'when no plans exist' do
        it "creates all default plans for circus_full" do
          expect {
            SubscriptionPlan.create_default_plans!
          }.to change(SubscriptionPlan, :count).by(8) # 4 plans × 2 circus types
        end

        it "creates day plan for circus_full" do
          SubscriptionPlan.create_default_plans!
          
          day_plan = SubscriptionPlan.find_by(name: "Journée - #{circus_full_type.name}")
          expect(day_plan).to be_present
          expect(day_plan.duration).to eq("day")
          expect(day_plan.price_cents).to eq(800)
        end

        it "creates trimester plan for circus_full" do
          SubscriptionPlan.create_default_plans!
          
          trimester_plan = SubscriptionPlan.find_by(name: "Trimestre - #{circus_full_type.name}")
          expect(trimester_plan).to be_present
          expect(trimester_plan.duration).to eq("trimester")
          expect(trimester_plan.price_cents).to eq(6000)
        end

        it "creates annual plan for circus_full" do
          SubscriptionPlan.create_default_plans!
          
          annual_plan = SubscriptionPlan.find_by(name: "Annuel - #{circus_full_type.name}")
          expect(annual_plan).to be_present
          expect(annual_plan.duration).to eq("annual")
          expect(annual_plan.price_cents).to eq(20000)
        end

        it "creates pack10 plan for circus_full" do
          SubscriptionPlan.create_default_plans!
          
          pack_plan = SubscriptionPlan.find_by(name: "Pack 10 séances - #{circus_full_type.name}")
          expect(pack_plan).to be_present
          expect(pack_plan.duration).to eq("pack10")
          expect(pack_plan.price_cents).to eq(7000)
          expect(pack_plan.sessions_count).to eq(10)
          expect(pack_plan.validity_days).to eq(365)
        end

        it "creates plans for circus_reduced" do
          SubscriptionPlan.create_default_plans!
          
          reduced_plan = SubscriptionPlan.find_by(name: "Journée - #{circus_reduced_type.name}")
          expect(reduced_plan).to be_present
        end

        it "does not create plans for basic membership types" do
          basic_type = create(:membership_type, :basic)
          
          SubscriptionPlan.create_default_plans!
          
          basic_plan = SubscriptionPlan.find_by("name LIKE ?", "%#{basic_type.name}%")
          expect(basic_plan).to be_nil
        end
      end

      context 'when plans already exist' do
        before do
          SubscriptionPlan.create_default_plans!
        end

        it "does not duplicate existing plans" do
          expect {
            SubscriptionPlan.create_default_plans!
          }.not_to change(SubscriptionPlan, :count)
        end

        it "keeps existing plan attributes" do
          existing_day_plan = SubscriptionPlan.find_by(name: "Journée - #{circus_full_type.name}")
          original_price = existing_day_plan.price_cents
          
          SubscriptionPlan.create_default_plans!
          
          existing_day_plan.reload
          expect(existing_day_plan.price_cents).to eq(original_price)
        end
      end
    end
  end
end

