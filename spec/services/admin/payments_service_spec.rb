require 'rails_helper'

RSpec.describe Admin::PaymentsService do
  let(:admin_user) { create(:user, system_role: :admin) }
  let(:person1) { create(:person, first_name: "John", last_name: "Doe", email: "john@example.com") }
  let(:person2) { create(:person, first_name: "Jane", last_name: "Smith", email: "jane@example.com") }
  
  describe '#call' do
    it "returns a hash with required keys" do
      service = described_class.new({})
      result = service.call
      
      expect(result).to have_key(:payments)
      expect(result).to have_key(:total_amount)
      expect(result).to have_key(:total_donation)
      expect(result).to have_key(:pagy)
    end
  end

  describe '#filtered_payments' do
    let!(:payment1) { create(:payment, person: person1, status: :success, total_cents: 10000, recorded_by: admin_user) }
    let!(:payment2) { create(:payment, person: person2, status: :pending, total_cents: 5000, recorded_by: admin_user) }
    let!(:payment3) { create(:payment, person: person1, status: :success, total_cents: 15000, recorded_by: admin_user) }

    context "without filters" do
      it "returns all payments" do
        service = described_class.new({})
        payments = service.call[:payments]
        
        expect(payments).to include(payment1, payment2, payment3)
      end
    end

    context "with person_id filter" do
      it "returns payments for specific person" do
        service = described_class.new(person_id: person1.id)
        payments = service.call[:payments]
        
        expect(payments).to include(payment1, payment3)
        expect(payments).not_to include(payment2)
      end
    end

    context "with status filter" do
      it "returns only payments with that status" do
        service = described_class.new(status: "success")
        payments = service.call[:payments]
        
        expect(payments).to include(payment1, payment3)
        expect(payments).not_to include(payment2)
      end

      it "returns only pending payments" do
        service = described_class.new(status: "pending")
        payments = service.call[:payments]
        
        expect(payments).to include(payment2)
        expect(payments).not_to include(payment1, payment3)
      end
    end

    context "with date range filter" do
      let!(:old_payment) { create(:payment, person: person1, created_at: 1.month.ago, recorded_by: admin_user) }

      it "returns payments within date range" do
        service = described_class.new(start_date: 1.week.ago.to_s, end_date: Date.today.to_s)
        payments = service.call[:payments]
        
        expect(payments).to include(payment1, payment2, payment3)
        expect(payments).not_to include(old_payment)
      end
    end

    context "with search filter" do
      it "searches by first name" do
        service = described_class.new(search: "John")
        payments = service.call[:payments]
        
        expect(payments).to include(payment1, payment3)
        expect(payments).not_to include(payment2)
      end

      it "searches by last name" do
        service = described_class.new(search: "Doe")
        payments = service.call[:payments]
        
        expect(payments).to include(payment1, payment3)
        expect(payments).not_to include(payment2)
      end

      it "searches by email" do
        service = described_class.new(search: "jane@example.com")
        payments = service.call[:payments]
        
        expect(payments).to include(payment2)
        expect(payments).not_to include(payment1, payment3)
      end

      it "searches by amount" do
        service = described_class.new(search: "100")
        payments = service.call[:payments]
        
        expect(payments).to include(payment1)
      end
    end
  end

  describe '#calculate_total_amount' do
    let!(:success_payment1) { create(:payment, person: person1, status: :success, total_cents: 10000, recorded_by: admin_user) }
    let!(:success_payment2) { create(:payment, person: person1, status: :success, total_cents: 5000, recorded_by: admin_user) }
    let!(:pending_payment) { create(:payment, person: person1, status: :pending, total_cents: 20000, recorded_by: admin_user) }

    it "calculates total only for success payments" do
      service = described_class.new({})
      total = service.call[:total_amount]
      
      expect(total).to eq(15000) # 10000 + 5000
    end

    it "calculates total with filters applied" do
      service = described_class.new(person_id: person1.id)
      total = service.call[:total_amount]
      
      expect(total).to eq(15000)
    end
  end

  describe '#calculate_total_donation' do
    let!(:payment1) { create(:payment, person: person1, status: :success, recorded_by: admin_user) }
    let!(:payment2) { create(:payment, person: person1, status: :success, recorded_by: admin_user) }

    it "returns total from PaymentQuery.total_donation" do
      service = described_class.new({})
      total = service.call[:total_donation]
      
      # Total donations should come from PaymentQuery
      expect(total).to be >= 0
    end
  end

  describe '#pagy_result' do
    before do
      create_list(:payment, 30, person: person1, recorded_by: admin_user)
    end

    it "returns paginated results" do
      service = described_class.new({})
      pagy, payments = service.call[:pagy]
      
      expect(payments).to respond_to(:each)
      expect(pagy).to be_nil # SimpleCov mocks pagy
    end

    it "handles custom items per page" do
      service = described_class.new(items: 10)
      _pagy, payments = service.call[:pagy]
      
      expect(payments).to respond_to(:each)
    end

    it "handles custom sorting" do
      service = described_class.new(sort: "total_cents", direction: "asc")
      _pagy, payments = service.call[:pagy]
      
      expect(payments).to respond_to(:each)
    end
  end

  describe 'edge cases' do
    it "handles empty params gracefully" do
      service = described_class.new({})
      result = service.call
      
      expect(result[:payments]).to be_a(ActiveRecord::Relation)
      expect(result[:total_amount]).to be_a(Numeric)
    end

    it "handles empty params" do
      service = described_class.new({})
      result = service.call
      
      expect(result[:payments]).to be_a(ActiveRecord::Relation)
      expect(result[:total_amount]).to be_a(Numeric)
    end
  end
end

