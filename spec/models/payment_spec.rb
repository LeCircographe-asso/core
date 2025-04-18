require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:payment)).to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:order) }
    it { should have_many(:product_orders).through(:order) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values([:success, :pending, :cancel]).with_default(:pending) }
    it { should define_enum_for(:payment_type).with_values([:cash, :credit_card, :check]) }
  end

  describe 'callbacks' do
    let(:payment) { create(:payment) }
    
    it 'calls update_user_membership_if_paid after update' do
      expect(payment).to receive(:update_user_membership_if_paid)
      payment.save
    end

    it 'calls createBookOfEntry after update' do
      expect(payment).to receive(:createBookOfEntry)
      payment.save
    end
  end

  describe '#payment_successful?' do
    let(:user) { create(:user) }
    let(:order) { create(:order, user: user) }
    let(:product) { create(:product, product_name: 'Cotisation 10 séances') }
    let!(:product_order) { create(:product_order, order: order, product: product) }
    let(:payment) { create(:payment, user: user, order: order) }

    context 'when payment is successful' do
      before do
        payment.update(status: :success)
      end

      it 'creates a book of entry' do
        expect {
          payment.payment_successful?
        }.to change(BookOfEntry, :count).by(1)
      end

      it 'creates book of entry with correct attributes' do
        payment.payment_successful?
        book_of_entry = BookOfEntry.last
        
        expect(book_of_entry.user_id).to eq(user.id)
        expect(book_of_entry.product_id).to eq(product.id)
        expect(book_of_entry.remaining).to eq(10)
        expect(book_of_entry.total_entry).to eq(10)
      end
    end

    context 'when payment is not successful' do
      it 'does not create a book of entry' do
        expect {
          payment.payment_successful?
        }.not_to change(BookOfEntry, :count)
      end
    end
  end

  describe '#determine_user_membership' do
    let(:payment) { create(:payment) }
    let(:circus_membership) { create(:membership, type_name: :Circus) }
    let(:basic_membership) { create(:membership, type_name: :Basic) }
    let(:no_member_membership) { create(:membership, type_name: :No_Member) }

    before do
      circus_membership
      basic_membership
      no_member_membership
    end

    context 'with circus products' do
      let(:product) { create(:product, product_name: 'Adhésion Cirque - Tarif Plein') }
      let!(:product_order) { create(:product_order, order: payment.order, product: product) }

      it 'returns circus membership' do
        expect(payment.determine_user_membership).to eq(circus_membership.id)
      end
    end

    context 'with basic products' do
      let(:product) { create(:product, product_name: 'Adhésion simple') }
      let!(:product_order) { create(:product_order, order: payment.order, product: product) }

      it 'returns basic membership' do
        expect(payment.determine_user_membership).to eq(basic_membership.id)
      end
    end

    context 'with donation' do
      let(:product) { create(:product, product_name: 'Donation') }
      let!(:product_order) { create(:product_order, order: payment.order, product: product) }

      it 'returns no member membership' do
        expect(payment.determine_user_membership).to eq(no_member_membership.id)
      end
    end
  end

  describe '#determine_end_date' do
    let(:payment) { create(:payment) }

    context 'with trimestrial subscription' do
      it 'returns date 3 months from now' do
        expect(payment.determine_end_date('Cotisation trimestrielle')).to be_within(1.second).of(3.months.from_now)
      end
    end

    context 'with daily pass' do
      it 'returns date 1 day from now' do
        expect(payment.determine_end_date('Pass journée')).to be_within(1.second).of(1.day.from_now)
      end
    end

    context 'with donation' do
      it 'returns nil' do
        expect(payment.determine_end_date('Donation')).to be_nil
      end
    end

    context 'with other products' do
      it 'returns date 1 year from now' do
        expect(payment.determine_end_date('Other Product')).to be_within(1.second).of(1.year.from_now)
      end
    end
  end

  describe '#update_user_membership_if_paid' do
    let(:user) { create(:user) }
    let(:order) { create(:order, user: user) }
    let(:product) { create(:product, product_name: 'Cotisation trimestrielle') }
    let!(:product_order) { create(:product_order, order: order, product: product) }
    let(:payment) { create(:payment, user: user, order: order) }

    context 'when payment is successful' do
      before do
        payment.update(status: :success)
      end

      it 'creates a new user membership if none exists' do
        expect {
          payment.update_user_membership_if_paid
        }.to change(UserMembership, :count).by(1)
      end

      it 'updates existing user membership if one exists' do
        create(:user_membership, user: user, status: :active)
        
        expect {
          payment.update_user_membership_if_paid
        }.not_to change(UserMembership, :count)
      end
    end

    context 'when payment is not successful' do
      it 'does not create or update user membership' do
        expect {
          payment.update_user_membership_if_paid
        }.not_to change(UserMembership, :count)
      end
    end
  end
end
