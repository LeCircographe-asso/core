# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserManagement::UserUpdater do
  let(:admin) { create(:user, :admin) }
  let(:person) { create(:person, email: 'person@example.com', phone: '0700000000') }
  let(:user) { create(:user, person: person, system_role: :volunteer) }

  describe '#call' do
    it 'updates user email and person attributes with instrumentation' do
      updater = described_class.new(
        user_id: user.id,
        email_address: 'new.email@example.com',
        person_attributes: { phone: '0711111111' },
        updated_by_id: admin.id
      )

      expect do
        result = updater.call
        expect(result.success?).to be(true)
      end.to instrument('user.updated')

      expect(user.reload.email_address).to eq('new.email@example.com')
      expect(person.reload.phone).to eq('0711111111')
    end

    it 'updates newsletter subscription when requested' do
      subscriber = create(:newsletter_subscriber, person: person, email: person.email, subscribed: false)

      updater = described_class.new(
        user_id: user.id,
        person_attributes: { phone: '0722222222' },
        newsletter_subscribed: true,
        updated_by_id: admin.id
      )

      result = updater.call
      expect(result.success?).to be(true)
      expect(subscriber.reload.subscribed?).to be(true)
    end

    it 'updates newsletter when the user updates their own settings (not only admin)' do
      create(:newsletter_subscriber, person: person, email: person.email, subscribed: false)

      updater = described_class.new(
        user_id: user.id,
        person_attributes: {},
        newsletter_subscribed: true,
        updated_by_id: user.id
      )

      expect(updater.call.success?).to be(true)
      expect(NewsletterSubscriber.find_by(email: person.email).subscribed?).to be(true)
    end

    it 'does not mutate newsletter when newsletter_subscribed is absent' do
      subscriber = create(:newsletter_subscriber, person: person, email: person.email, subscribed: true)

      updater = described_class.new(
        user_id: user.id,
        person_attributes: { phone: "0733333333" },
        updated_by_id: admin.id
      )

      result = updater.call
      expect(result.success?).to be(true)
      expect(subscriber.reload.subscribed?).to be(true)
    end

    it 'returns validation errors when update fails' do
      updater = described_class.new(
        user_id: user.id,
        person_attributes: { first_name: '' },
        updated_by_id: admin.id
      )

      result = updater.call

      expect(result.success?).to be(false)
      expect(result.message).to include(I18n.t("services.validation.invalid_data"))
    end

    it 'fails when permissions are insufficient' do
      other_user = create(:user, system_role: :volunteer)

      updater = described_class.new(
        user_id: user.id,
        email_address: 'unauthorized@example.com',
        updated_by_id: other_user.id
      )

      result = updater.call

      expect(result.success?).to be(false)
      expect(result.message).to include(I18n.t("services.errors.insufficient_permissions.user_update"))
      expect(user.reload.email_address).not_to eq('unauthorized@example.com')
    end
  end
end
