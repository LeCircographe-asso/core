require 'rails_helper'

RSpec.describe Payments::Process do
  let(:person) { create(:person) }
  let(:user) { create(:user) }
  let(:payment) { create(:payment, person: person, recorded_by: user, status: :pending) }
  let(:service) { Payments::Process.new(payment) }

  describe '#call' do
    context 'when payment is nil' do
      it 'returns failure' do
        service = Payments::Process.new(nil)
        result = service.call
        
        expect(result.success?).to be false
        expect(result.message).to eq("Payment is required")
      end
    end

    context 'when payment is already processed' do
      it 'returns failure' do
        payment.update!(status: :success)
        result = service.call
        
        expect(result.success?).to be false
        expect(result.message).to eq("Payment is already processed")
      end
    end

    context 'when payment processing fails' do
      it 'returns failure with error message' do
        allow(service).to receive(:process_payment_lines).and_raise(ActiveRecord::RecordInvalid.new(payment))
        
        result = service.call
        
        expect(result.success?).to be false
        expect(result.errors).to include(a_string_matching(/Record invalid/i))
      end
    end

    context 'when payment processing succeeds' do
      it 'returns success' do
        result = service.call
        
        expect(result.success?).to be true
        expect(result.payment).to eq(payment)
        expect(result.message).to eq("Payment processed successfully")
      end

      it 'updates payment status to success' do
        service.call
        
        expect(payment.reload.status).to eq("success")
      end
    end
  end

  describe '#process_payment_lines' do
    context 'with membership payment line' do
      let(:membership) { create(:membership, person: person, status: :pending) }
      let(:payment_line) { create(:payment_line, payment: payment, item: membership, item_type: "Membership") }

      it 'activates pending membership' do
        expect(membership.status).to eq("pending")
        
        service.call
        
        expect(membership.reload.status).to eq("active")
      end

      it 'assigns member number if person has no member number' do
        expect(person.member_number).to be_blank
        
        allow(MemberManagementService).to receive(:assign_member_number).and_return("25U001")
        
        service.call
        
        expect(MemberManagementService).to have_received(:assign_member_number).with(person)
        expect(person.reload.member_number).to eq("25U001")
      end

      it 'does not assign member number if person already has one' do
        person.update!(member_number: "25U001")
        
        service.call
        
        expect(person.reload.member_number).to eq("25U001")
      end
    end

    context 'with subscription plan payment line' do
      let(:membership_type) { create(:membership_type, category: :circus_full) }
      let(:subscription_plan) { create(:subscription_plan, membership_type: membership_type, duration: :pack10, sessions_count: 10) }
      let(:payment_line) { create(:payment_line, payment: payment, item: subscription_plan, item_type: "SubscriptionPlan") }

      it 'creates book of entry for pack plans' do
        expect {
          service.call
        }.to change(BookOfEntry, :count).by(1)
        
        book_of_entry = BookOfEntry.last
        expect(book_of_entry.person).to eq(person)
        expect(book_of_entry.subscription_plan).to eq(subscription_plan)
        expect(book_of_entry.sessions_remaining).to eq(10)
        expect(book_of_entry.status).to eq("active")
      end

      it 'does not create book of entry for non-pack plans' do
        subscription_plan.update!(duration: :annual)
        
        expect {
          service.call
        }.not_to change(BookOfEntry, :count)
      end
    end

    context 'with membership type payment line' do
      let(:membership_type) { create(:membership_type) }
      let(:payment_line) { create(:payment_line, payment: payment, item: membership_type, item_type: "MembershipType") }

      it 'creates new membership' do
        expect {
          service.call
        }.to change(Membership, :count).by(1)
        
        membership = Membership.last
        expect(membership.person).to eq(person)
        expect(membership.membership_type).to eq(membership_type)
        expect(membership.status).to eq("active")
        expect(membership.started_at).to eq(Date.current)
        expect(membership.ended_at).to eq(Date.current + 1.year)
      end

      it 'assigns member number when creating membership' do
        allow(MemberManagementService).to receive(:assign_member_number).and_return("25U001")
        
        service.call
        
        expect(MemberManagementService).to have_received(:assign_member_number).with(person)
      end
    end

    context 'with multiple payment lines' do
      let(:membership) { create(:membership, person: person, status: :pending) }
      let(:membership_type) { create(:membership_type) }
      let!(:membership_line) { create(:payment_line, payment: payment, item: membership, item_type: "Membership") }
      let!(:membership_type_line) { create(:payment_line, payment: payment, item: membership_type, item_type: "MembershipType") }

      it 'processes all payment lines' do
        expect {
          service.call
        }.to change(Membership, :count).by(1)
        
        expect(membership.reload.status).to eq("active")
      end
    end
  end

  describe '#create_book_of_entry' do
    let(:subscription_plan) { create(:subscription_plan, sessions_count: 10, validity_days: 365) }

    it 'creates book of entry with correct attributes' do
      book_of_entry = service.send(:create_book_of_entry, person, subscription_plan)
      
      expect(book_of_entry).to be_persisted
      expect(book_of_entry.person).to eq(person)
      expect(book_of_entry.subscription_plan).to eq(subscription_plan)
      expect(book_of_entry.sessions_remaining).to eq(10)
      expect(book_of_entry.status).to eq("active")
    end
  end

  describe '#create_membership' do
    let(:membership_type) { create(:membership_type) }

    it 'creates membership with correct attributes' do
      membership = service.send(:create_membership, person, membership_type)
      
      expect(membership).to be_persisted
      expect(membership.person).to eq(person)
      expect(membership.membership_type).to eq(membership_type)
      expect(membership.started_at).to eq(Date.current)
      expect(membership.ended_at).to eq(Date.current + 1.year)
      expect(membership.status).to eq("active")
      expect(membership.first_joined_at).to eq(Date.current)
    end

    it 'assigns member number if person has no member number' do
      allow(MemberManagementService).to receive(:assign_member_number).and_return("25U001")
      
      service.send(:create_membership, person, membership_type)
      
      expect(MemberManagementService).to have_received(:assign_member_number).with(person)
    end
  end

  describe '#update_payment_status' do
    it 'updates payment status to success' do
      service.send(:update_payment_status)
      
      expect(payment.reload.status).to eq("success")
    end
  end

  describe 'transaction handling' do
    let(:membership) { create(:membership, person: person, status: :pending) }
    let(:payment_line) { create(:payment_line, payment: payment, item: membership, item_type: "Membership") }

    it 'rolls back all changes on error' do
      allow(membership).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(membership))
      
      expect {
        service.call
      }.to raise_error(ActiveRecord::RecordInvalid)
      
      expect(payment.reload.status).to eq("pending")
    end

    it 'commits all changes on success' do
      service.call
      
      expect(payment.reload.status).to eq("success")
      expect(membership.reload.status).to eq("active")
    end
  end

  describe 'edge cases' do
    context 'when person is nil for subscription plan' do
      let(:subscription_plan) { create(:subscription_plan, duration: :pack10) }
      let(:payment_line) { create(:payment_line, payment: payment, item: subscription_plan, item_type: "SubscriptionPlan") }

      it 'handles gracefully' do
        payment.update!(person: nil)
        
        expect {
          service.call
        }.not_to raise_error
      end
    end

    context 'when person is nil for membership type' do
      let(:membership_type) { create(:membership_type) }
      let(:payment_line) { create(:payment_line, payment: payment, item: membership_type, item_type: "MembershipType") }

      it 'handles gracefully' do
        payment.update!(person: nil)
        
        expect {
          service.call
        }.not_to raise_error
      end
    end

    context 'when payment has no payment lines' do
      it 'processes successfully' do
        result = service.call
        
        expect(result.success?).to be true
        expect(payment.reload.status).to eq("success")
      end
    end
  end

  describe 'integration with other services' do
    let(:membership) { create(:membership, person: person, status: :pending) }
    let(:payment_line) { create(:payment_line, payment: payment, item: membership, item_type: "Membership") }

    it 'integrates with MemberManagementService' do
      expect(MemberManagementService).to receive(:assign_member_number).with(person).and_return("25U001")
      
      service.call
      
      expect(person.reload.member_number).to eq("25U001")
    end

    it 'integrates with BookOfEntry creation' do
      subscription_plan = create(:subscription_plan, duration: :pack10, sessions_count: 10)
      create(:payment_line, payment: payment, item: subscription_plan, item_type: "SubscriptionPlan")
      
      expect {
        service.call
      }.to change(BookOfEntry, :count).by(1)
    end
  end
end
