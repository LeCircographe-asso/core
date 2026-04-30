# frozen_string_literal: true

require 'rails_helper'

RSpec.describe People::AccountLinker do
  let(:source_person) { create(:person, email: 'source@example.com', phone: '0101010101') }
  let(:target_person) { create(:person, email: 'target@example.com') }
  let(:user) { create(:user, person: source_person) }

  describe '#call' do
    context 'with valid parameters' do
      it 'reassigns the user to the target person' do
        result = described_class.new(user: user, target_person: target_person).call

        expect(result.success?).to be(true)
        expect(user.reload.person).to eq(target_person)
        expect(result.source_person).to eq(source_person)
      end

      it 'destroys the source person when requested' do
        source_id = source_person.id

        result = described_class.new(
          user: user,
          target_person: target_person,
          destroy_source_person: true
        ).call

        expect(result.success?).to be(true)
        expect(Person.exists?(source_id)).to be_falsey
      end
    end

    context 'with invalid parameters' do
      it 'fails when target already has a different user' do
        create(:user, person: target_person)

        result = described_class.new(user: user, target_person: target_person).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Target person already has a user account')
      end

      it 'fails when user already linked to the target' do
        user.update!(person: target_person)

        result = described_class.new(user: user, target_person: target_person).call

        expect(result.success?).to be(false)
        expect(result.message).to include('already linked')
      end

      it 'fails when target not provided' do
        result = described_class.new(user: user).call

        expect(result.success?).to be(false)
        expect(result.message).to include(I18n.t('services.validation.invalid_data'))
      end
    end
  end
end
