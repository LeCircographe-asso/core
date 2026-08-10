# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MembershipType, type: :model do
  describe 'validations' do
    it 'can be created' do
      membership_type = MembershipType.new(
        name: 'Adhésion Basique',
        category: :basic,
        price_cents: 1500,
        version: 1,
        effective_from: Date.current
      )
      expect(membership_type).to be_present
    end

    it 'requires name' do
      membership_type = MembershipType.new(category: :basic, price_cents: 1500, version: 1, effective_from: Date.current)
      expect(membership_type).not_to be_valid
      expect(membership_type.errors[:name]).to include(I18n.t('errors.messages.blank'))
    end

    it 'requires category' do
      membership_type = MembershipType.new(name: 'Test', price_cents: 1500, version: 1, effective_from: Date.current)
      expect(membership_type).not_to be_valid
      expect(membership_type.errors[:category]).to include(I18n.t('errors.messages.blank'))
    end

    it 'requires price_cents' do
      membership_type = MembershipType.new(name: 'Test', category: :basic, version: 1, effective_from: Date.current)
      expect(membership_type).not_to be_valid
      expect(membership_type.errors[:price_cents]).to include(I18n.t('errors.messages.blank'))
    end

    it 'requires price_cents to be greater than 0' do
      membership_type = MembershipType.new(name: 'Test', category: :basic, price_cents: 0, version: 1, effective_from: Date.current)
      expect(membership_type).not_to be_valid
      expect(membership_type.errors[:price_cents]).to include(I18n.t('errors.messages.greater_than', count: 0))
    end

    # SKIP: version has default value 1, so no error when missing
    # it "requires version" do
    # end

    it 'requires version to be greater than 0' do
      membership_type = MembershipType.new(name: 'Test', category: :basic, price_cents: 1500, version: 0, effective_from: Date.current)
      expect(membership_type).not_to be_valid
      expect(membership_type.errors[:version]).to include(I18n.t('errors.messages.greater_than', count: 0))
    end

    it 'requires effective_from' do
      membership_type = MembershipType.new(name: 'Test', category: :basic, price_cents: 1500, version: 1)
      expect(membership_type).not_to be_valid
      expect(membership_type.errors[:effective_from]).to include(I18n.t('errors.messages.blank'))
    end

    it 'requires a valid rate_kind' do
      membership_type = build(:membership_type, rate_kind: "vip")

      expect(membership_type).not_to be_valid
      expect(membership_type.errors[:rate_kind]).to include(I18n.t('errors.messages.inclusion'))
    end

    it 'validates name uniqueness scoped to version' do
      create(:membership_type, name: 'Test Type', version: 1)

      duplicate = MembershipType.new(name: 'Test Type', version: 1, category: :basic, price_cents: 1500, effective_from: Date.current)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include(I18n.t('errors.messages.taken'))
    end

    it 'allows same name with different version' do
      create(:membership_type, name: 'Test Type', version: 1)

      different_version = MembershipType.new(name: 'Test Type', version: 2, category: :basic, price_cents: 1500, effective_from: Date.current)
      expect(different_version).to be_valid
    end

    it 'has valid category values' do
      membership_type = create(:membership_type, category: :basic)
      expect(membership_type.category).to eq('basic')

      membership_type = create(:membership_type, category: :circus)
      expect(membership_type.category).to eq('circus')

      membership_type = create(:membership_type, category: :event)
      expect(membership_type.category).to eq('event')
    end
  end

  describe 'associations' do
    it 'has many memberships' do
      membership_type = create(:membership_type)
      membership1 = create(:membership, membership_type: membership_type)
      membership2 = create(:membership, membership_type: membership_type)

      expect(membership_type.memberships).to include(membership1, membership2)
    end

    it 'has many contribution_formulas' do
      membership_type = create(:membership_type)
      plan1 = create(:contribution_formula, membership_type: membership_type)
      plan2 = create(:contribution_formula, membership_type: membership_type)

      expect(membership_type.contribution_formulas).to include(plan1, plan2)
    end

    it 'belongs to created_by_user' do
      user = create(:user)
      membership_type = create(:membership_type, created_by_user: user)
      expect(membership_type.created_by_user).to eq(user)
    end

    it 'allows created_by_user to be nil' do
      membership_type = create(:membership_type, created_by_user: nil)
      expect(membership_type.created_by_user).to be_nil
    end
  end

  describe 'scopes' do
    let!(:basic_type) { create(:membership_type, category: :basic) }
    let!(:circus_full_type) { create(:membership_type, category: :circus) }
    let!(:circus_reduced_type) { create(:membership_type, category: :circus) }
    let!(:active_type) { create(:membership_type, :with_membership) }
    let!(:current_version) { create(:membership_type, effective_until: nil) }
    let!(:old_version) { create(:membership_type, effective_until: Date.current - 1.day) }

    it 'finds circus types' do
      expect(MembershipType.circus_types).to include(circus_full_type, circus_reduced_type)
      expect(MembershipType.circus_types).not_to include(basic_type)
    end

    it 'finds basic types' do
      expect(MembershipType.basic_types).to include(basic_type)
      expect(MembershipType.basic_types).not_to include(circus_full_type, circus_reduced_type)
    end

    it 'orders by price' do
      expensive_type = create(:membership_type, price_cents: 5000)
      cheap_type = create(:membership_type, price_cents: 1000)

      ordered_types = MembershipType.by_price
      expect(ordered_types.first).to eq(cheap_type)
      expect(ordered_types.last).to eq(expensive_type)
    end

    it 'finds active types' do
      expect(MembershipType.active).to include(active_type)
    end

    it 'finds current versions' do
      expect(MembershipType.current_versions).to include(current_version)
      expect(MembershipType.current_versions).not_to include(old_version)
    end

    it 'finds effective on specific date' do
      effective_date = Date.current
      effective_type = create(:membership_type, effective_from: effective_date - 1.day, effective_until: effective_date + 1.day)
      not_effective_type = create(:membership_type, effective_from: effective_date + 1.day)

      expect(MembershipType.effective_on(effective_date)).to include(effective_type)
      expect(MembershipType.effective_on(effective_date)).not_to include(not_effective_type)
    end

    it 'orders price history' do
      # Use same name to test price history properly
      old_type = create(:membership_type, name: 'History Test', effective_from: Date.current - 1.year)
      new_type = create(:membership_type, name: 'History Test', version: 2, effective_from: Date.current)

      ordered_history = MembershipType.where(name: 'History Test').price_history
      expect(ordered_history.first).to eq(old_type)
      expect(ordered_history.last).to eq(new_type)
    end
  end

  describe '#circus?' do
    it 'returns true for circus category' do
      membership_type = create(:membership_type, category: :circus)
      expect(membership_type.circus?).to be true
    end

    it 'returns false for basic category' do
      membership_type = create(:membership_type, category: :basic)
      expect(membership_type.circus?).to be false
    end

    it 'returns false for event category' do
      membership_type = create(:membership_type, category: :event)
      expect(membership_type.circus?).to be false
    end
  end

  describe '#basic?' do
    it 'returns true for basic category' do
      membership_type = create(:membership_type, category: :basic)
      expect(membership_type.basic?).to be true
    end

    it 'returns false for circus category' do
      membership_type = create(:membership_type, category: :circus)
      expect(membership_type.basic?).to be false
    end

    it 'returns false for event category' do
      membership_type = create(:membership_type, category: :event)
      expect(membership_type.basic?).to be false
    end
  end

  describe '#available_for?' do
    let(:standard_type) { build(:membership_type, :circus, rate_kind: "standard") }
    let(:reduced_type) { build(:membership_type, :circus, rate_kind: "reduced") }
    let(:person) { build(:person, reduced_rate_eligible: false) }

    it 'allows standard rates for everyone' do
      expect(standard_type.available_for?(person)).to be(true)
    end

    it 'hides reduced rates when the person is not eligible' do
      expect(reduced_type.available_for?(person)).to be(false)
    end

    it 'allows reduced rates when the person is eligible' do
      person.reduced_rate_eligible = true
      person.reduced_rate_reason = "Étudiant"

      expect(reduced_type.available_for?(person)).to be(true)
    end
  end

  describe '.available_for' do
    let(:person) { create(:person) }
    let!(:standard_type) { create(:membership_type, :circus, rate_kind: "standard", effective_until: nil) }
    let!(:reduced_type) { create(:membership_type, :circus_reduced, rate_kind: "reduced", effective_until: nil) }
    let!(:expired_reduced_type) { create(:membership_type, :circus_reduced, rate_kind: "reduced", effective_until: Date.current - 1.day) }

    it 'returns current standard rates for everyone' do
      expect(described_class.available_for(person)).to include(standard_type)
      expect(described_class.available_for(person)).not_to include(reduced_type, expired_reduced_type)
    end

    it 'returns current reduced rates only for eligible people' do
      person.update!(reduced_rate_eligible: true, reduced_rate_reason: "Étudiant")

      expect(described_class.available_for(person)).to include(standard_type, reduced_type)
      expect(described_class.available_for(person)).not_to include(expired_reduced_type)
    end
  end

  describe '#price_euros' do
    it 'converts cents to euros' do
      membership_type = create(:membership_type, price_cents: 1500)
      expect(membership_type.price_euros).to eq(15.0)
    end
  end

  describe '#price_euros=' do
    it 'converts euros to cents' do
      membership_type = create(:membership_type)
      membership_type.price_euros = 15.50
      expect(membership_type.price_cents).to eq(1550)
    end
  end

  describe '#name_with_price' do
    it 'returns name with price in euros' do
      membership_type = create(:membership_type, name: 'Adhésion Basique', price_cents: 1500)
      expect(membership_type.name_with_price).to eq('Adhésion Basique - 15.0€')
    end
  end

  describe '#current_version?' do
    it 'returns true when effective_until is nil' do
      membership_type = create(:membership_type, effective_until: nil)
      expect(membership_type.current_version?).to be true
    end

    it 'returns false when effective_until is set' do
      membership_type = create(:membership_type, effective_until: Date.current - 1.day)
      expect(membership_type.current_version?).to be false
    end
  end

  describe '#create_price_change!' do
    let(:user) { create(:user) }
    let(:membership_type) { create(:membership_type, price_cents: 1500, version: 1, effective_until: nil) }

    context 'when the current version was never sold (no memberships)' do
      it 'merges the price in place instead of creating a new version' do
        result = membership_type.create_price_change!(2000, reason: 'Correction', user: user)

        expect(result).to equal(membership_type)
        expect(membership_type.reload.price_cents).to eq(2000)
        expect(membership_type.version).to eq(1)
        expect(membership_type.effective_until).to be_nil
        expect(membership_type.change_reason).to eq('Correction')
      end

      it 'does not create an additional MembershipType row' do
        membership_type
        expect { membership_type.create_price_change!(2000) }.not_to change(MembershipType, :count)
      end

      it 'logs the merge in PriceChangeLog' do
        expect { membership_type.create_price_change!(2000, user: user) }
          .to change(PriceChangeLog, :count).by(1)

        log = PriceChangeLog.last
        expect(log.loggable).to eq(membership_type)
        expect(log.action).to eq('merged')
        expect(log.user).to eq(user)
      end
    end

    context 'when the current version has already been sold (at least one membership)' do
      before { create(:membership, membership_type: membership_type) }

      it 'creates new version with new price' do
        new_effective_date = Date.current + 1.month
        new_version = membership_type.create_price_change!(
          2000,
          effective_from: new_effective_date,
          reason: 'Price increase',
          user: user
        )

        expect(new_version).to be_persisted
        expect(new_version).not_to equal(membership_type)
        expect(new_version.price_cents).to eq(2000)
        expect(new_version.version).to eq(2)
        expect(new_version.effective_from).to eq(new_effective_date)
        expect(new_version.effective_until).to be_nil
        expect(new_version.created_by_user).to eq(user)
        expect(new_version.change_reason).to eq('Price increase')
      end

      it 'closes current version' do
        new_effective_date = Date.current + 1.month
        membership_type.create_price_change!(2000, effective_from: new_effective_date)

        expect(membership_type.reload.effective_until).to eq(new_effective_date - 1.day)
      end

      it 'uses current date as default effective_from' do
        new_version = membership_type.create_price_change!(2000)

        expect(new_version.effective_from).to eq(Date.current)
      end

      it 'does not change the price on the old (already sold) version' do
        membership_type.create_price_change!(2000)

        expect(membership_type.reload.price_cents).to eq(1500)
      end

      it 'logs the version fork in PriceChangeLog' do
        expect { membership_type.create_price_change!(2000, user: user) }
          .to change(PriceChangeLog, :count).by(1)

        expect(PriceChangeLog.last.action).to eq('versioned')
      end
    end
  end

  describe '#archive!' do
    let(:membership_type) { create(:membership_type, effective_until: nil) }

    it 'closes the current version without creating a replacement' do
      membership_type
      expect { membership_type.archive! }.not_to change(MembershipType, :count)
      expect(membership_type.reload.effective_until).to eq(Date.current)
      expect(membership_type.current_version?).to be false
    end

    it 'excludes the archived type from current_versions' do
      membership_type.archive!
      expect(MembershipType.current_versions).not_to include(membership_type)
    end

    it 'keeps existing memberships untouched' do
      membership = create(:membership, membership_type: membership_type)
      membership_type.archive!

      expect(membership.reload.membership_type).to eq(membership_type)
    end

    it 'logs the archival in PriceChangeLog' do
      expect { membership_type.archive!(user: create(:user)) }.to change(PriceChangeLog, :count).by(1)
      expect(PriceChangeLog.last.action).to eq('archived')
    end
  end

  describe '#price_evolution' do
    it 'returns price history for same name' do
      type1 = create(:membership_type, name: 'Test Type', version: 1, effective_from: Date.current - 1.year)
      type2 = create(:membership_type, name: 'Test Type', version: 2, effective_from: Date.current)

      history = type2.price_evolution
      expect(history).to include(type1, type2)
    end
  end

  describe '#price_change_percentage' do
    let(:from_date) { Date.current - 1.year }
    let(:to_date) { Date.current }

    it 'calculates price change percentage' do
      create(:membership_type, name: 'Test Type', version: 1, effective_from: from_date, price_cents: 1000)
      new_type = create(:membership_type, name: 'Test Type', version: 2, effective_from: to_date, price_cents: 1200)

      percentage = new_type.price_change_percentage(from_date, to_date)
      expect(percentage).to eq(20.0) # (1200-1000)/1000 * 100
    end

    it 'returns nil when old price is missing' do
      new_type = create(:membership_type, name: 'Test Type', version: 2, effective_from: to_date, price_cents: 1200)

      percentage = new_type.price_change_percentage(from_date, to_date)
      expect(percentage).to be_nil
    end

    it 'returns nil when new price is missing' do
      old_type = create(:membership_type, name: 'Test Type', version: 1, effective_from: from_date, price_cents: 1000)

      percentage = old_type.price_change_percentage(from_date, to_date)
      expect(percentage).to be_nil
    end

    # SKIP: Cannot test with price_cents: 0 as model validation prevents it
    # it "returns nil when old price is zero" do
    # end
  end

  describe 'class methods' do
    describe '.create_default_types!' do
      it 'ensures default membership types exist with expected attributes' do
        MembershipType.create_default_types!

        basic_type = MembershipType.find_by(name: 'Adhésion Basique', version: 1)
        expect(basic_type).to be_present
        expect(basic_type.category).to eq('basic')
        expect(basic_type.price_cents).to eq(1500)

        circus_full_type = MembershipType.find_by(name: 'Adhésion Cirque Complète', version: 1)
        expect(circus_full_type).to be_present
        expect(circus_full_type.category).to eq('circus')
        expect(circus_full_type.price_cents).to eq(2500)

        circus_reduced_type = MembershipType.find_by(name: 'Adhésion Cirque Réduite', version: 1)
        expect(circus_reduced_type).to be_present
        expect(circus_reduced_type.category).to eq('circus')
        expect(circus_reduced_type.price_cents).to eq(2000)
      end

      it 'is idempotent and does not create duplicate rows' do
        MembershipType.create_default_types!

        expect do
          MembershipType.create_default_types!
        end.not_to change(MembershipType, :count)
      end
    end
  end
end
