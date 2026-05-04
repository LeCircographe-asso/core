# frozen_string_literal: true

require 'rails_helper'

RSpec.describe People::AccountMerger do
  let(:source_person) { create(:person, email: 'source@example.com') }
  let(:target_person) { create(:person, email: 'target@example.com') }

  describe '#call' do
    context 'with valid params' do
      it 'transfers memberships, payments and subscriptions' do
        membership = create(:membership, person: source_person)
        payment = create(:payment, person: source_person)
        book = create(:contribution, person: source_person)

        result = described_class.new(
          source_person: source_person,
          target_person: target_person,
          actor_id: create(:user).id
        ).call

        expect(result.success?).to be(true)
        expect(membership.reload.person).to eq(target_person)
        expect(payment.reload.person).to eq(target_person)
        expect(book.reload.person).to eq(target_person)
      end

      it 'transfers account claims and member number histories before destroying source' do
        claim = create(:account_claim, person: source_person)
        history = create(:member_number_history, person: source_person, member_number: "26U001")

        result = described_class.new(
          source_person: source_person,
          target_person: target_person
        ).call

        expect(result.success?).to be(true)
        expect(claim.reload.person_id).to eq(target_person.id)
        expect(history.reload.person_id).to eq(target_person.id)
        expect(Person.exists?(source_person.id)).to be false
      end

      it 'destroys the source person by default' do
        result = described_class.new(
          source_person: source_person,
          target_person: target_person
        ).call

        expect(result.success?).to be(true)
        expect(Person.exists?(source_person.id)).to be_falsey
      end

      it 'keeps source person when destroy_source is false' do
        result = described_class.new(
          source_person: source_person,
          target_person: target_person,
          destroy_source: false
        ).call

        expect(result.success?).to be(true)
        expect(Person.exists?(source_person.id)).to be_truthy
        expect(source_person.reload.user).to be_nil
      end
    end

    context 'with invalid params' do
      it 'fails when source equals target' do
        result = described_class.new(source_person: source_person, target_person: source_person).call

        expect(result.success?).to be(false)
        expect(result.message).to include('identical')
      end

      it 'fails when target missing' do
        result = described_class.new(source_person: source_person).call

        expect(result.success?).to be(false)
        expect(result.message).to include(I18n.t('services.validation.invalid_data'))
      end
    end
  end
end
