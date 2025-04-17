require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:order) }
    it { should have_many(:product_orders).through(:order) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values([ :success, :pending, :cancel ]) }
    it { should define_enum_for(:payment_type).with_values([ :cash, :credit_card, :check ]) }
  end

  describe 'callbacks' do
    it 'calls update_user_membership_if_paid after update' do
      payment = build(:payment)
      expect(payment).to receive(:update_user_membership_if_paid)
      payment.run_callbacks(:update)
    end

    it 'calls createBookOfEntry after update' do
      payment = build(:payment)
      expect(payment).to receive(:createBookOfEntry)
      payment.run_callbacks(:update)
    end
  end

  describe '#determine_user_membership' do
    let(:user) { create(:user) }
    let(:order) { create(:order, user: user) }
    let!(:circus_membership) { create(:membership, :circus) }
    let!(:basic_membership) { create(:membership, :basic) }
    let!(:no_member) { create(:membership, :no_member) }

    context 'with circus products' do
      it 'returns circus membership id for circus products' do
        circus_products = [
          "Adhésion Cirque - Tarif Plein",
          "Upgrade Basic to Cirque - Tarif Plein",
          "Upgrade Basic to Cirque - Tarif Réduit",
          "Cotisation annuelle",
          "Cotisation trimestrielle",
          "Cotisation 10 séances",
          "Pass journée"
        ]

        circus_products.each do |product_name|
          product = create(:product, product_name: product_name)
          product_order = create(:product_order, product: product, order: order, user: user)
          payment = create(:payment, user: user, order: order)

          allow(payment).to receive(:product_orders).and_return([ product_order ])

          expect(payment.determine_user_membership).to eq(circus_membership.id)
        end
      end
    end

    context 'with basic membership product' do
      it 'returns basic membership id for basic membership product' do
        product = create(:product, product_name: "Adhésion simple")
        product_order = create(:product_order, product: product, order: order, user: user)
        payment = create(:payment, user: user, order: order)

        allow(payment).to receive(:product_orders).and_return([ product_order ])

        expect(payment.determine_user_membership).to eq(basic_membership.id)
      end
    end

    context 'with donation product' do
      it 'returns no member id for donation product' do
        product = create(:product, product_name: "Donation")
        product_order = create(:product_order, product: product, order: order, user: user)
        payment = create(:payment, user: user, order: order)

        allow(payment).to receive(:product_orders).and_return([ product_order ])

        expect(payment.determine_user_membership).to eq(no_member.id)
      end
    end
  end

  describe '#determine_end_date' do
    let(:payment) { build(:payment) }

    it 'returns 3 months from now for quarterly subscription' do
      result = payment.determine_end_date("Cotisation trimestrielle")
      expect(result).to be_within(1.minute).of(3.months.from_now)
    end

    it 'returns 1 day from now for day pass' do
      result = payment.determine_end_date("Pass journée")
      expect(result).to be_within(1.minute).of(1.day.from_now)
    end

    it 'returns nil for donation' do
      result = payment.determine_end_date("Donation")
      expect(result).to be_nil
    end

    it 'returns 1 year from now for other products' do
      result = payment.determine_end_date("Adhésion simple")
      expect(result).to be_within(1.minute).of(1.year.from_now)
    end
  end

  describe '#update_user_membership_end_date' do
    let(:user) { create(:user) }
    let(:membership) { create(:membership) }
    let(:user_membership) { create(:user_membership, user: user, membership: membership) }
    let(:product) { create(:product, product_name: "Cotisation annuelle") }
    let(:order) { create(:order, user: user) }
    let(:product_order) { create(:product_order, product: product, order: order, user: user) }
    let(:payment) { create(:payment, user: user, order: order) }

    before do
      allow(payment).to receive(:product_orders).and_return([ product_order ])
    end

    it 'updates user membership end date based on product' do
      expect(user_membership).to receive(:update!).with(status: :active, end_date: anything)
      payment.update_user_membership_end_date(user_membership)
    end
  end

  describe '#createBookOfEntry' do
    let(:user) { create(:user) }
    let(:order) { create(:order, user: user) }
    let(:payment) { create(:payment, user: user, order: order) }

    context 'with 10 sessions product' do
      let(:product) { create(:product, :ten_sessions) }
      let(:product_order) { create(:product_order, product: product, order: order, user: user) }

      before do
        allow(payment).to receive(:product_orders).and_return([ product_order ])
      end

      it 'creates a book of entry with 10 remaining entries' do
        expect {
          payment.createBookOfEntry
        }.to change(BookOfEntry, :count).by(1)

        book_entry = BookOfEntry.last
        expect(book_entry.user_id).to eq(user.id)
        expect(book_entry.product_id).to eq(product.id)
        expect(book_entry.remaining).to eq(10)
        expect(book_entry.total_entry).to eq(10)
      end
    end

    context 'with other products' do
      let(:product) { create(:product, :basic_membership) }
      let(:product_order) { create(:product_order, product: product, order: order, user: user) }

      before do
        allow(payment).to receive(:product_orders).and_return([ product_order ])
      end

      it 'does not create a book of entry' do
        expect {
          payment.createBookOfEntry
        }.not_to change(BookOfEntry, :count)
      end
    end
  end

  describe '#update_user_membership_if_paid' do
    let(:user) { create(:user) }
    let(:order) { create(:order, user: user) }
    let(:payment) { create(:payment, user: user, order: order) }
    let(:membership) { create(:membership) }

    before do
      allow(payment).to receive(:payment_successful?).and_return(true)
      allow(payment).to receive(:determine_user_membership).and_return(membership.id)
    end

    context 'when user has no active membership' do
      it 'creates a new user membership' do
        expect(UserMembership).to receive(:create!).with(
          hash_including(user: user, membership_id: membership.id, status: :active)
        ).and_return(instance_double(UserMembership, update!: true))

        payment.update_user_membership_if_paid
      end
    end

    context 'when user has an active membership' do
      let!(:user_membership) { create(:user_membership, user: user, membership: membership, status: :active) }

      it 'updates the existing user membership' do
        expect(user_membership).to receive(:update!).with(membership_id: membership.id)
        expect(payment).to receive(:update_user_membership_end_date).with(user_membership)

        payment.update_user_membership_if_paid
      end
    end
  end
end
