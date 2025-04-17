RSpec.describe Order, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:order)).to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:product_orders) }
    it { should have_many(:payments) }
    it { should have_many(:products).through(:product_orders) }
  end

  describe 'validations' do
    it { should validate_presence_of(:user_id) }
  end

  describe 'calculations' do
    let(:user) { create(:user) }
    let(:order) { create(:order, user: user) }
    let(:product1) { create(:product, price: 100) }
    let(:product2) { create(:product, price: 200) }
    
    before do
      create(:product_order, order: order, product: product1, quantity: 2)
      create(:product_order, order: order, product: product2, quantity: 1)
    end

    describe '#total_amount' do
      it 'calculates the total amount correctly' do
        # (100 * 2) + (200 * 1) = 400
        expect(order.total_amount).to eq(400)
      end
    end
  end

  describe 'scopes' do
    let!(:pending_order) { create(:order, status: :pending) }
    let!(:completed_order) { create(:order, status: :completed) }
    let!(:cancelled_order) { create(:order, status: :cancelled) }

    describe '.pending' do
      it 'returns only pending orders' do
        expect(Order.pending).to include(pending_order)
        expect(Order.pending).not_to include(completed_order, cancelled_order)
      end
    end

    describe '.completed' do
      it 'returns only completed orders' do
        expect(Order.completed).to include(completed_order)
        expect(Order.completed).not_to include(pending_order, cancelled_order)
      end
    end
  end

  describe 'payment status' do
    let(:order) { create(:order) }
    let(:payment) { create(:payment, order: order) }

    describe '#paid?' do
      context 'when order has a successful payment' do
        before do
          payment.update(status: :success)
        end

        it 'returns true' do
          expect(order.paid?).to be true
        end
      end

      context 'when order has no successful payment' do
        before do
          payment.update(status: :pending)
        end

        it 'returns false' do
          expect(order.paid?).to be false
        end
      end
    end

    describe '#payment_status' do
      context 'when order has a successful payment' do
        before do
          payment.update(status: :success)
        end

        it 'returns :paid' do
          expect(order.payment_status).to eq(:paid)
        end
      end

      context 'when order has a pending payment' do
        before do
          payment.update(status: :pending)
        end

        it 'returns :pending' do
          expect(order.payment_status).to eq(:pending)
        end
      end

      context 'when order has no payments' do
        it 'returns :unpaid' do
          expect(order.payment_status).to eq(:unpaid)
        end
      end
    end
  end

  describe 'product management' do
    let(:order) { create(:order) }
    let(:product) { create(:product) }

    describe '#add_product' do
      it 'creates a new product order' do
        expect {
          order.add_product(product, 2)
        }.to change(ProductOrder, :count).by(1)
      end

      it 'sets the correct quantity' do
        order.add_product(product, 2)
        expect(order.product_orders.last.quantity).to eq(2)
      end

      it 'updates existing product order if product already exists' do
        create(:product_order, order: order, product: product, quantity: 1)
        
        expect {
          order.add_product(product, 2)
        }.not_to change(ProductOrder, :count)
        
        expect(order.product_orders.last.quantity).to eq(3)
      end
    end

    describe '#remove_product' do
      let!(:product_order) { create(:product_order, order: order, product: product, quantity: 2) }

      it 'decreases the quantity of the product order' do
        order.remove_product(product)
        expect(product_order.reload.quantity).to eq(1)
      end

      it 'destroys the product order if quantity becomes zero' do
        order.remove_product(product)
        order.remove_product(product)
        expect(ProductOrder.exists?(product_order.id)).to be false
      end
    end
  end
end 