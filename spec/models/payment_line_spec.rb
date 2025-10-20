require 'rails_helper'

RSpec.describe PaymentLine, type: :model do
  describe 'validations' do
    it "can be created" do
      payment = create(:payment)
      membership = create(:membership)
      payment_line = PaymentLine.new(payment: payment, item: membership, amount_cents: 1500)
      expect(payment_line).to be_present
    end

    it "requires a payment" do
      membership = create(:membership)
      payment_line = PaymentLine.new(item: membership, amount_cents: 1500)
      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:payment]).to include("must exist")
    end

    it "requires an item" do
      payment = create(:payment)
      payment_line = PaymentLine.new(payment: payment, amount_cents: 1500)
      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:item]).to include("must exist")
    end

    it "requires amount_cents" do
      payment = create(:payment)
      membership = create(:membership)
      payment_line = PaymentLine.new(payment: payment, item: membership)
      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:amount_cents]).to include("can't be blank")
    end

    it "requires amount_cents to be greater than 0" do
      payment = create(:payment)
      membership = create(:membership)
      payment_line = PaymentLine.new(payment: payment, item: membership, amount_cents: 0)
      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:amount_cents]).to include("must be greater than 0")
    end

    it "requires item_type" do
      payment = create(:payment)
      membership = create(:membership)
      payment_line = PaymentLine.new(payment: payment, item: membership, amount_cents: 1500)
      payment_line.item_type = nil
      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:item_type]).to include("can't be blank")
    end

    it "requires item_id" do
      payment = create(:payment)
      membership = create(:membership)
      payment_line = PaymentLine.new(payment: payment, item: membership, amount_cents: 1500)
      payment_line.item_id = nil
      expect(payment_line).not_to be_valid
      expect(payment_line.errors[:item_id]).to include("can't be blank")
    end

    it "validates uniqueness of payment_id scoped to item_type and item_id" do
      payment = create(:payment)
      membership = create(:membership)
      create(:payment_line, payment: payment, item: membership, amount_cents: 1500)
      
      duplicate_line = PaymentLine.new(payment: payment, item: membership, amount_cents: 2000)
      expect(duplicate_line).not_to be_valid
      expect(duplicate_line.errors[:payment_id]).to include("has already been taken")
    end
  end

  describe 'associations' do
    it "belongs to a payment" do
      payment = create(:payment)
      payment_line = create(:payment_line, payment: payment)
      expect(payment_line.payment).to eq(payment)
    end

    it "belongs to a polymorphic item (membership)" do
      membership = create(:membership)
      payment_line = create(:payment_line, item: membership)
      expect(payment_line.item).to eq(membership)
      expect(payment_line.item_type).to eq("Membership")
    end

    it "belongs to a polymorphic item (subscription_plan)" do
      subscription_plan = create(:subscription_plan)
      payment_line = create(:payment_line, item: subscription_plan)
      expect(payment_line.item).to eq(subscription_plan)
      expect(payment_line.item_type).to eq("SubscriptionPlan")
    end

    it "belongs to a polymorphic item (membership_type)" do
      membership_type = create(:membership_type)
      payment_line = create(:payment_line, item: membership_type)
      expect(payment_line.item).to eq(membership_type)
      expect(payment_line.item_type).to eq("MembershipType")
    end
  end

  describe 'scopes' do
    let!(:membership_line) { create(:payment_line, item: create(:membership), item_type: "Membership") }
    let!(:subscription_line) { create(:payment_line, item: create(:subscription_plan), item_type: "SubscriptionPlan") }
    let!(:membership_type_line) { create(:payment_line, item: create(:membership_type), item_type: "MembershipType") }

    it "finds membership lines" do
      expect(PaymentLine.memberships).to include(membership_line)
      expect(PaymentLine.memberships).not_to include(subscription_line, membership_type_line)
    end

    it "finds subscription plan lines" do
      expect(PaymentLine.subscription_plans).to include(subscription_line)
      expect(PaymentLine.subscription_plans).not_to include(membership_line, membership_type_line)
    end

    it "finds membership type lines" do
      expect(PaymentLine.membership_types).to include(membership_type_line)
      expect(PaymentLine.membership_types).not_to include(membership_line, subscription_line)
    end

    it "finds lines by item type" do
      expect(PaymentLine.by_item_type("Membership")).to include(membership_line)
      expect(PaymentLine.by_item_type("SubscriptionPlan")).to include(subscription_line)
      expect(PaymentLine.by_item_type("MembershipType")).to include(membership_type_line)
    end
  end

  describe '#item_description' do
    it "returns description for membership" do
      membership_type = create(:membership_type, name: "Adhésion Basique")
      membership = create(:membership, membership_type: membership_type)
      payment_line = create(:payment_line, item: membership)
      
      expect(payment_line.item_description).to eq("Adhésion Adhésion Basique")
    end

    it "returns description for subscription_plan" do
      subscription_plan = create(:subscription_plan, name: "Plan Trimestriel", duration: "trimester")
      payment_line = create(:payment_line, item: subscription_plan)
      
      expect(payment_line.item_description).to eq("Plan Trimestriel (trimester)")
    end

    it "returns description for membership_type" do
      membership_type = create(:membership_type, name: "Adhésion Cirque")
      payment_line = create(:payment_line, item: membership_type)
      
      expect(payment_line.item_description).to eq("Adhésion Adhésion Cirque")
    end

    it "returns humanized item_type for unknown types" do
      payment_line = create(:payment_line)
      payment_line.item_type = "UnknownType"
      
      expect(payment_line.item_description).to eq("Unknowntype")
    end
  end

  describe '#amount_euros' do
    it "converts cents to euros" do
      payment_line = PaymentLine.new(amount_cents: 1500)
      expect(payment_line.amount_euros).to eq(15.0)
    end
  end

  describe '#amount_euros=' do
    it "converts euros to cents" do
      payment_line = PaymentLine.new
      payment_line.amount_euros = 15.50
      expect(payment_line.amount_cents).to eq(1550)
    end
  end

  describe 'class methods' do
    let(:payment) { create(:payment) }

    describe '.create_for_membership!' do
      it "creates payment line for membership" do
        membership = create(:membership)
        
        payment_line = PaymentLine.create_for_membership!(payment, membership, 1500)
        
        expect(payment_line).to be_persisted
        expect(payment_line.payment).to eq(payment)
        expect(payment_line.item).to eq(membership)
        expect(payment_line.item_type).to eq("Membership")
        expect(payment_line.amount_cents).to eq(1500)
        expect(payment_line.description).to eq("Adhésion #{membership.membership_type.name}")
      end
    end

    describe '.create_for_subscription_plan!' do
      it "creates payment line for subscription plan" do
        subscription_plan = create(:subscription_plan, name: "Plan Trimestriel", duration: "trimester")
        
        payment_line = PaymentLine.create_for_subscription_plan!(payment, subscription_plan, 6000)
        
        expect(payment_line).to be_persisted
        expect(payment_line.payment).to eq(payment)
        expect(payment_line.item).to eq(subscription_plan)
        expect(payment_line.item_type).to eq("SubscriptionPlan")
        expect(payment_line.amount_cents).to eq(6000)
        expect(payment_line.description).to eq("Plan Trimestriel (trimester)")
      end
    end

    describe '.create_for_membership_type!' do
      it "creates payment line for membership type" do
        membership_type = create(:membership_type, name: "Adhésion Cirque")
        
        payment_line = PaymentLine.create_for_membership_type!(payment, membership_type, 2500)
        
        expect(payment_line).to be_persisted
        expect(payment_line.payment).to eq(payment)
        expect(payment_line.item).to eq(membership_type)
        expect(payment_line.item_type).to eq("MembershipType")
        expect(payment_line.amount_cents).to eq(2500)
        expect(payment_line.description).to eq("Adhésion Adhésion Cirque")
      end
    end
  end
end
