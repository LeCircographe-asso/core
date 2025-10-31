require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'validations' do
    it "can be created" do
      person = create(:person)
      user = create(:user)
      payment = Payment.new(person: person, recorded_by: user, total_cents: 1500, status: :pending)
      expect(payment).to be_present
    end

    it "requires a person" do
      user = create(:user)
      payment = Payment.new(recorded_by: user, total_cents: 1500, status: :pending)
      expect(payment).not_to be_valid
      expect(payment.errors[:person]).to include("must exist")
    end

    it "requires a recorded_by user" do
      person = create(:person)
      payment = Payment.new(person: person, total_cents: 1500, status: :pending)
      expect(payment).not_to be_valid
      expect(payment.errors[:recorded_by]).to include("must exist")
    end

    it "has valid status values" do
      person = create(:person)
      user = create(:user)
      payment = Payment.new(person: person, recorded_by: user, total_cents: 1500, status: :success)
      expect(payment.status).to eq("success")
    end

    it "has valid payment_method values" do
      person = create(:person)
      user = create(:user)
      payment = Payment.new(person: person, recorded_by: user, total_cents: 1500, payment_method: :card)
      expect(payment.payment_method).to eq("card")
    end
  end

  describe 'associations' do
    it "belongs to a person" do
      person = create(:person)
      payment = create(:payment, person: person)
      expect(payment.person).to eq(person)
    end

    it "belongs to a recorded_by user" do
      user = create(:user)
      payment = create(:payment, recorded_by: user)
      expect(payment.recorded_by).to eq(user)
    end

    it "has many payment_lines" do
      payment = create(:payment)
      payment_line1 = create(:payment_line, payment: payment)
      payment_line2 = create(:payment_line, payment: payment)
      
      expect(payment.payment_lines).to include(payment_line1, payment_line2)
    end

    it "has many payment_audit_logs" do
      payment = create(:payment)
      audit_log = create(:payment_audit_log, payment: payment)
      
      expect(payment.payment_audit_logs).to include(audit_log)
    end
  end

  describe 'scopes' do
    let!(:success_payment) { create(:payment, status: :success) }
    let!(:pending_payment) { create(:payment, status: :pending) }
    let!(:cancel_payment) { create(:payment, status: :cancel) }

    it "finds active payments" do
      expect(Payment.active).to include(success_payment, pending_payment)
      expect(Payment.active).not_to include(cancel_payment)
    end
  end

  describe 'callbacks' do
    it "generates uuid before create" do
      payment = build(:payment)
      expect(payment.uuid).to be_nil
      
      payment.save!
      
      expect(payment.uuid).to be_present
      expect(payment.uuid).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it "creates audit log after create" do
      payment = build(:payment)
      
      expect {
        payment.save!
      }.to change(PaymentAuditLog, :count).by(1)
      
      audit_log = PaymentAuditLog.last
      expect(audit_log.payment).to eq(payment)
      expect(audit_log.action).to eq("create")
    end

    it "logs status changes after update" do
      payment = create(:payment, status: :pending)
      payment.save! # Ensure it's persisted with pending status
      
      # Mock the audit log creation to verify it's called
      expect(PaymentAuditLog).to receive(:log).with(payment, payment.recorded_by, "status_change", anything)
      
      payment.update!(status: :success)
    end

    it "invalidates cache on status change" do
      payment = create(:payment, status: :pending)
      
      # Set cache first
      Rails.cache.write("total_successful_payments", 1000)
      Rails.cache.write("total_donations", 500)
      
      payment.update!(status: :success)
      
      expect(Rails.cache.read("total_successful_payments")).to be_nil
      expect(Rails.cache.read("total_donations")).to be_nil
    end
  end

  describe 'class methods' do
    describe '.total_successful_amount' do
      before do
        # Clear cache before test
        Rails.cache.clear
      end

      let!(:success_payment1) { create(:payment, status: :success, total_cents: 1500) }
      let!(:success_payment2) { create(:payment, status: :success, total_cents: 2500) }
      let!(:pending_payment) { create(:payment, status: :pending, total_cents: 1000) }

      it "returns total amount of successful payments" do
        expect(Payment.total_successful_amount).to eq(4000) # 1500 + 2500
      end

      it "caches the result" do
        expect(Rails.cache).to receive(:fetch).with("total_successful_payments", expires_in: 1.hour).and_call_original
        Payment.total_successful_amount
      end
    end

    describe '.total_donations' do
      it "returns total donations" do
        expect(Payment.total_donations).to eq(0) # No donations in test data
      end

      it "caches the result" do
        expect(Rails.cache).to receive(:fetch).with("total_donations", expires_in: 1.hour).and_call_original
        Payment.total_donations
      end
    end
  end

  describe '#payment_type' do
    let(:person) { create(:person) }
    let(:user) { create(:user) }
    let(:payment) { create(:payment, person: person, recorded_by: user) }

    it "returns 'Adhésion' when payment has membership lines" do
      membership = create(:membership)
      create(:payment_line, payment: payment, item: membership, item_type: "Membership")
      
      expect(payment.payment_type).to eq("Adhésion")
    end

    it "returns 'Cotisation' when payment has subscription plan lines" do
      subscription_plan = create(:subscription_plan)
      create(:payment_line, payment: payment, item: subscription_plan, item_type: "SubscriptionPlan")
      
      expect(payment.payment_type).to eq("Cotisation")
    end

    it "returns item description when payment has other lines" do
      membership_type = create(:membership_type, name: "Adhésion Cirque")
      create(:payment_line, payment: payment, item: membership_type, item_type: "MembershipType")
      
      expect(payment.payment_type).to eq("Adhésion Cirque")
    end

    it "returns 'Autre' when payment has no lines" do
      expect(payment.payment_type).to eq("Autre")
    end
  end

  describe '#price_euros (from Priceable)' do
    it "converts cents to euros" do
      payment = Payment.new(total_cents: 1500)
      expect(payment.price_euros).to eq(15.0)
    end
  end

  describe '#price_euros= (from Priceable)' do
    it "converts euros to cents" do
      payment = Payment.new
      payment.price_euros = 15.50
      expect(payment.total_cents).to eq(1550)
    end
  end

  describe '#payment_method_humanized' do
    it "returns humanized payment method" do
      payment = Payment.new(payment_method: :cash)
      expect(payment.payment_method_humanized).to eq("Espèces")
    end

    it "returns humanized payment method for card" do
      payment = Payment.new(payment_method: :card)
      expect(payment.payment_method_humanized).to eq("Carte bancaire")
    end

    it "returns humanized payment method for cheque" do
      payment = Payment.new(payment_method: :cheque)
      expect(payment.payment_method_humanized).to eq("Chèque")
    end

    it "returns humanized payment method for transfer" do
      payment = Payment.new(payment_method: :transfer)
      expect(payment.payment_method_humanized).to eq("Virement")
    end

    it "returns humanized payment method for offered" do
      payment = Payment.new(payment_method: :offered)
      expect(payment.payment_method_humanized).to eq("Offert")
    end
  end

  describe '#is_offered?' do
    it "returns true for offered payment method" do
      payment = Payment.new(payment_method: :offered)
      expect(payment.is_offered?).to be true
    end

    it "returns false for other payment methods" do
      payment = Payment.new(payment_method: :cash)
      expect(payment.is_offered?).to be false
    end
  end

  describe '#is_paid?' do
    it "returns true for success status" do
      payment = Payment.new(status: :success)
      expect(payment.is_paid?).to be true
    end

    it "returns false for other statuses" do
      payment = Payment.new(status: :pending)
      expect(payment.is_paid?).to be false
    end
  end

  describe '#can_be_cancelled?' do
    it "returns true for recent pending payment" do
      payment = create(:payment, status: :pending, created_at: 1.hour.ago)
      expect(payment.can_be_cancelled?).to be true
    end

    it "returns false for old payment" do
      payment = create(:payment, status: :pending, created_at: 25.hours.ago)
      expect(payment.can_be_cancelled?).to be false
    end

    it "returns false for cancelled payment" do
      payment = create(:payment, status: :cancel, created_at: 1.hour.ago)
      expect(payment.can_be_cancelled?).to be false
    end
  end

  describe '#membership_related?' do
    let(:person) { create(:person) }
    let(:user) { create(:user) }
    let(:payment) { create(:payment, person: person, recorded_by: user) }

    it "returns true when payment has membership lines" do
      membership = create(:membership)
      create(:payment_line, payment: payment, item: membership, item_type: "Membership")
      
      expect(payment.membership_related?).to be true
    end

    it "returns false when payment has no membership lines" do
      subscription_plan = create(:subscription_plan)
      create(:payment_line, payment: payment, item: subscription_plan, item_type: "SubscriptionPlan")
      
      expect(payment.membership_related?).to be false
    end
  end

  describe '#carnet_related?' do
    let(:person) { create(:person) }
    let(:user) { create(:user) }
    let(:payment) { create(:payment, person: person, recorded_by: user) }

    it "returns true when payment has pack subscription plan lines" do
      subscription_plan = create(:subscription_plan, :pack10)
      create(:payment_line, payment: payment, item: subscription_plan, item_type: "SubscriptionPlan")
      
      expect(payment.carnet_related?).to be true
    end

    it "returns false when payment has no pack subscription plan lines" do
      subscription_plan = create(:subscription_plan, :annual)
      create(:payment_line, payment: payment, item: subscription_plan, item_type: "SubscriptionPlan")
      
      expect(payment.carnet_related?).to be false
    end
  end

  describe '#handle_user_deletion' do
    it "cancels payment and logs deletion" do
      payment = create(:payment, status: :success)
      
      expect {
        payment.handle_user_deletion
      }.to change(PaymentAuditLog, :count).by(1)
      
      expect(payment.reload.status).to eq("cancel")
      
      audit_log = PaymentAuditLog.last
      expect(audit_log.payment).to eq(payment)
      expect(audit_log.action).to eq("user_deleted")
    end

    it "invalidates cache" do
      payment = create(:payment, status: :success)
      
      Rails.cache.write("total_successful_payments", 1000)
      Rails.cache.write("total_donations", 500)
      
      payment.handle_user_deletion
      
      expect(Rails.cache.read("total_successful_payments")).to be_nil
      expect(Rails.cache.read("total_donations")).to be_nil
    end
  end

  describe '#can_cancel?' do
    it "returns true for non-cancelled payment" do
      payment = create(:payment, status: :success)
      expect(payment.can_cancel?).to be true
    end

    it "returns false for cancelled payment" do
      payment = create(:payment, status: :cancel)
      expect(payment.can_cancel?).to be false
    end
  end

  describe '#destroy' do
    it "logs deletion and invalidates cache" do
      payment = create(:payment)
      initial_count = PaymentAuditLog.count
      
      Rails.cache.write("total_successful_payments", 1000)
      Rails.cache.write("total_donations", 500)
      
      # Mock the audit log creation to verify it's called
      expect(PaymentAuditLog).to receive(:log).with(payment, payment.recorded_by, "delete")
      
      payment.destroy
      
      expect(Rails.cache.read("total_successful_payments")).to be_nil
      expect(Rails.cache.read("total_donations")).to be_nil
    end
  end
end
