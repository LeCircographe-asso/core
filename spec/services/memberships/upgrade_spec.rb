require 'rails_helper'

RSpec.describe Memberships::Upgrade do
  let(:person) { create(:person) }
  let(:basic_membership_type) { create(:membership_type, category: :basic) }
  let(:circus_full_membership_type) { create(:membership_type, category: :circus, name: "Adhésion Cirque Complète", price_cents: 2500) }
  let(:circus_reduced_membership_type) { create(:membership_type, category: :circus, name: "Adhésion Cirque Réduite", price_cents: 2000) }
  let(:basic_membership) { create(:membership, person: person, membership_type: basic_membership_type, status: :active) }

  describe '#call' do
    context 'when membership is nil' do
      it 'returns failure' do
        service = Memberships::Upgrade.new(nil, circus_full_membership_type)
        result = service.call
        
        expect(result.success?).to be false
        expect(result.message).to eq("Membership is required")
      end
    end

    context 'when new_membership_type is nil' do
      it 'returns failure' do
        service = Memberships::Upgrade.new(basic_membership, nil)
        result = service.call
        
        expect(result.success?).to be false
        expect(result.message).to eq("New membership type is required")
      end
    end

    context 'when upgrade is not allowed' do
      it 'returns failure for same membership type' do
        service = Memberships::Upgrade.new(basic_membership, basic_membership_type)
        result = service.call
        
        expect(result.success?).to be false
        expect(result.message).to eq("Cannot upgrade to the same membership type")
      end

      it 'returns failure for downgrade from circus to basic' do
        circus_membership = create(:membership, person: person, membership_type: circus_full_membership_type, status: :active)
        service = Memberships::Upgrade.new(circus_membership, basic_membership_type)
        result = service.call
        
        expect(result.success?).to be false
        expect(result.message).to eq("Cannot downgrade from circus to basic membership")
      end
    end

    context 'when upgrade is allowed' do
      it 'returns success for basic to circus_full upgrade' do
        service = Memberships::Upgrade.new(basic_membership, circus_full_membership_type)
        result = service.call
        
        expect(result.success?).to be true
        expect(result.message).to eq("Membership upgraded successfully")
        expect(result.new_membership).to be_persisted
        expect(result.old_membership).to eq(basic_membership)
      end

      it 'returns success for basic to circus_reduced upgrade' do
        service = Memberships::Upgrade.new(basic_membership, circus_reduced_membership_type)
        result = service.call
        
        expect(result.success?).to be true
        expect(result.new_membership).to be_persisted
      end

      it 'returns success for circus_full to circus_reduced upgrade' do
        circus_full_membership = create(:membership, person: person, membership_type: circus_full_membership_type, status: :active)
        service = Memberships::Upgrade.new(circus_full_membership, circus_reduced_membership_type)
        result = service.call
        
        expect(result.success?).to be true
        expect(result.new_membership).to be_persisted
      end

      it 'returns success for circus_reduced to circus_full upgrade' do
        circus_reduced_membership = create(:membership, person: person, membership_type: circus_reduced_membership_type, status: :active)
        service = Memberships::Upgrade.new(circus_reduced_membership, circus_full_membership_type)
        result = service.call
        
        expect(result.success?).to be true
        expect(result.new_membership).to be_persisted
      end
    end

    context 'when upgrade fails' do
      it 'returns failure with error message' do
        allow(basic_membership).to receive(:upgrade_to!).and_raise(StandardError.new("Upgrade failed"))
        
        service = Memberships::Upgrade.new(basic_membership, circus_full_membership_type)
        result = service.call
        
        expect(result.success?).to be false
        expect(result.message).to eq("Upgrade failed")
      end
    end
  end

  describe 'upgrade logic' do
    let(:original_first_joined_at) { Date.current - 6.months }
    let(:basic_membership_with_history) do
      create(:membership, 
        person: person, 
        membership_type: basic_membership_type, 
        status: :active,
        first_joined_at: original_first_joined_at
      )
    end

    it 'creates new membership with correct attributes' do
      service = Memberships::Upgrade.new(basic_membership_with_history, circus_full_membership_type)
      result = service.call
      
      new_membership = result.new_membership
      expect(new_membership.person).to eq(person)
      expect(new_membership.membership_type).to eq(circus_full_membership_type)
      expect(new_membership.status).to eq("active")
      expect(new_membership.started_at).to eq(Date.current)
      expect(new_membership.ended_at).to eq(Date.current + 1.year)
    end

    it 'preserves first_joined_at date' do
      service = Memberships::Upgrade.new(basic_membership_with_history, circus_full_membership_type)
      result = service.call
      
      expect(result.new_membership.first_joined_at).to eq(original_first_joined_at)
    end

    it 'marks old membership as inactive' do
      service = Memberships::Upgrade.new(basic_membership, circus_full_membership_type)
      result = service.call
      
      expect(basic_membership.reload.status).to eq("inactive")
    end

    it 'uses custom start date when provided' do
      custom_start_date = Date.current + 1.month
      service = Memberships::Upgrade.new(basic_membership, circus_full_membership_type, custom_start_date)
      result = service.call
      
      new_membership = result.new_membership
      expect(new_membership.started_at).to eq(custom_start_date)
      expect(new_membership.ended_at).to eq(custom_start_date + 1.year)
    end
  end

  describe 'validation logic' do
    it 'allows basic to circus_full upgrade' do
      service = Memberships::Upgrade.new(basic_membership, circus_full_membership_type)
      expect(service.send(:upgrade_allowed?)).to be true
    end

    it 'allows basic to circus_reduced upgrade' do
      service = Memberships::Upgrade.new(basic_membership, circus_reduced_membership_type)
      expect(service.send(:upgrade_allowed?)).to be true
    end

    it 'allows circus_full to circus_reduced upgrade' do
      circus_full_membership = create(:membership, person: person, membership_type: circus_full_membership_type, status: :active)
      service = Memberships::Upgrade.new(circus_full_membership, circus_reduced_membership_type)
      expect(service.send(:upgrade_allowed?)).to be true
    end

    it 'allows circus_reduced to circus_full upgrade' do
      circus_reduced_membership = create(:membership, person: person, membership_type: circus_reduced_membership_type, status: :active)
      service = Memberships::Upgrade.new(circus_reduced_membership, circus_full_membership_type)
      expect(service.send(:upgrade_allowed?)).to be true
    end

    it 'prevents upgrade to same type' do
      service = Memberships::Upgrade.new(basic_membership, basic_membership_type)
      expect(service.send(:upgrade_allowed?)).to be false
    end

    it 'prevents downgrade from circus to basic' do
      circus_membership = create(:membership, person: person, membership_type: circus_full_membership_type, status: :active)
      service = Memberships::Upgrade.new(circus_membership, basic_membership_type)
      expect(service.send(:upgrade_allowed?)).to be false
    end
  end

  describe 'error handling' do
    it 'handles membership upgrade errors gracefully' do
      allow(basic_membership).to receive(:upgrade_to!).and_raise(ActiveRecord::RecordInvalid.new(basic_membership))
      
      service = Memberships::Upgrade.new(basic_membership, circus_full_membership_type)
      result = service.call
      
      expect(result.success?).to be false
      expect(result.message).to include("Record invalid")
    end

    it 'handles database errors gracefully' do
      allow(basic_membership).to receive(:upgrade_to!).and_raise(ActiveRecord::StatementInvalid.new("Database error"))
      
      service = Memberships::Upgrade.new(basic_membership, circus_full_membership_type)
      result = service.call
      
      expect(result.success?).to be false
      expect(result.message).to eq("Database error")
    end
  end

  describe 'integration with membership model' do
    it 'delegates to membership.upgrade_to!' do
      expect(basic_membership).to receive(:upgrade_to!).with(circus_full_membership_type, Date.current).and_return(double('new_membership'))
      
      service = Memberships::Upgrade.new(basic_membership, circus_full_membership_type)
      service.call
    end

    it 'passes custom start date to membership.upgrade_to!' do
      custom_start_date = Date.current + 1.month
      expect(basic_membership).to receive(:upgrade_to!).with(circus_full_membership_type, custom_start_date).and_return(double('new_membership'))
      
      service = Memberships::Upgrade.new(basic_membership, circus_full_membership_type, custom_start_date)
      service.call
    end
  end

  describe 'edge cases' do
    context 'when membership is inactive' do
      let(:inactive_membership) { create(:membership, person: person, membership_type: basic_membership_type, status: :inactive) }

      it 'still allows upgrade' do
        service = Memberships::Upgrade.new(inactive_membership, circus_full_membership_type)
        result = service.call
        
        expect(result.success?).to be true
      end
    end

    context 'when membership is expired' do
      let(:expired_membership) { create(:membership, person: person, membership_type: basic_membership_type, status: :expired) }

      it 'still allows upgrade' do
        service = Memberships::Upgrade.new(expired_membership, circus_full_membership_type)
        result = service.call
        
        expect(result.success?).to be true
      end
    end

    context 'when person has no active membership' do
      it 'still allows upgrade' do
        service = Memberships::Upgrade.new(basic_membership, circus_full_membership_type)
        result = service.call
        
        expect(result.success?).to be true
      end
    end
  end

  describe 'business logic validation' do
    it 'validates that upgrade follows business rules' do
      # Test all valid upgrade paths
      valid_upgrades = [
        [basic_membership_type, circus_full_membership_type],
        [basic_membership_type, circus_reduced_membership_type],
        [circus_full_membership_type, circus_reduced_membership_type],
        [circus_reduced_membership_type, circus_full_membership_type]
      ]
      
      valid_upgrades.each do |from_type, to_type|
        membership = create(:membership, person: person, membership_type: from_type, status: :active)
        service = Memberships::Upgrade.new(membership, to_type)
        
        expect(service.send(:upgrade_allowed?)).to be true, "Upgrade from #{from_type.category} to #{to_type.category} should be allowed"
      end
    end

    it 'validates that invalid upgrades are rejected' do
      # Test invalid upgrade paths
      invalid_upgrades = [
        [basic_membership_type, basic_membership_type], # Same type
        [circus_full_membership_type, basic_membership_type], # Downgrade
        [circus_reduced_membership_type, basic_membership_type] # Downgrade
      ]
      
      invalid_upgrades.each do |from_type, to_type|
        membership = create(:membership, person: person, membership_type: from_type, status: :active)
        service = Memberships::Upgrade.new(membership, to_type)
        
        expect(service.send(:upgrade_allowed?)).to be false, "Upgrade from #{from_type.category} to #{to_type.category} should not be allowed"
      end
    end
  end
end
