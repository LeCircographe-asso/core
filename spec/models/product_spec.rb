RSpec.describe Product, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:product)).to be_valid
    end
  end

  describe 'associations' do
    it { should have_many(:book_of_entries) }
    it { should have_many(:price_entries) }
    it { should have_many(:price_catalogs).through(:price_entries) }
    it { should have_many(:product_orders) }
    it { should have_many(:orders).through(:product_orders) }
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'calls productValidation' do
        product = build(:product)
        expect(product).to receive(:productValidation)
        product.save
      end
    end
  end

  describe '#current_price' do
    let(:product) { create(:product) }
    let(:price_catalog) { create(:price_catalog) }
    
    context 'when product has price entries' do
      let!(:old_price_entry) { create(:price_entry, product: product, price_catalog: price_catalog, created_at: 2.days.ago) }
      let!(:new_price_entry) { create(:price_entry, product: product, price_catalog: price_catalog, created_at: 1.day.ago) }
      let!(:latest_price_entry) { create(:price_entry, product: product, price_catalog: price_catalog, created_at: Time.current) }

      it 'returns the most recent price entry' do
        expect(product.current_price).to eq(latest_price_entry)
      end
    end

    context 'when product has no price entries' do
      it 'returns nil' do
        expect(product.current_price).to be_nil
      end
    end
  end

  describe '#productValidation' do
    context 'when product name is blank' do
      let(:product) { build(:product, product_name: '') }

      it 'logs an error message' do
        expect(Rails.logger).to receive(:error).with(/Le produit .* n'a pas de nom./)
        product.save
      end
    end

    context 'when product name is present' do
      let(:product) { build(:product, product_name: 'Valid Product') }

      it 'does not log an error message' do
        expect(Rails.logger).not_to receive(:error)
        product.save
      end
    end
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_product) { create(:product, active: true) }
      let!(:inactive_product) { create(:product, active: false) }

      it 'returns only active products' do
        expect(Product.active).to include(active_product)
        expect(Product.active).not_to include(inactive_product)
      end
    end
  end

  describe 'price management' do
    let(:product) { create(:product) }
    let(:price_catalog) { create(:price_catalog) }

    describe '#add_price' do
      it 'creates a new price entry' do
        expect {
          product.add_price(price_catalog, 100)
        }.to change(PriceEntry, :count).by(1)
      end

      it 'sets the correct price' do
        price_entry = product.add_price(price_catalog, 100)
        expect(price_entry.price).to eq(100)
      end
    end

    describe '#latest_price' do
      context 'when product has price entries' do
        before do
          create(:price_entry, product: product, price_catalog: price_catalog, price: 100, created_at: 2.days.ago)
          create(:price_entry, product: product, price_catalog: price_catalog, price: 200, created_at: 1.day.ago)
        end

        it 'returns the latest price' do
          expect(product.latest_price).to eq(200)
        end
      end

      context 'when product has no price entries' do
        it 'returns nil' do
          expect(product.latest_price).to be_nil
        end
      end
    end
  end

  describe 'order management' do
    let(:product) { create(:product) }
    let(:order) { create(:order) }

    describe '#add_to_order' do
      it 'creates a new product order' do
        expect {
          product.add_to_order(order, 2)
        }.to change(ProductOrder, :count).by(1)
      end

      it 'sets the correct quantity' do
        product_order = product.add_to_order(order, 2)
        expect(product_order.quantity).to eq(2)
      end

      it 'updates existing product order if product already in order' do
        create(:product_order, product: product, order: order, quantity: 1)
        
        expect {
          product.add_to_order(order, 2)
        }.not_to change(ProductOrder, :count)
        
        expect(order.product_orders.last.quantity).to eq(3)
      end
    end
  end
end 