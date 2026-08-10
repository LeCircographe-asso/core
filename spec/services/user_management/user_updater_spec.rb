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

    it 'allows an admin to assign a role within their assignable_roles' do
      updater = described_class.new(
        user_id: user.id, # volunteer
        system_role: 'web_visitor',
        updated_by_id: admin.id
      )

      result = updater.call

      expect(result.success?).to be(true)
      expect(user.reload.system_role).to eq('web_visitor')
    end

    it 'rejects an admin promoting a user to super_admin (not in assignable_roles)' do
      updater = described_class.new(
        user_id: user.id, # volunteer
        system_role: 'super_admin',
        updated_by_id: admin.id
      )

      result = updater.call

      expect(result.success?).to be(false)
      expect(result.message).to include(I18n.t("services.errors.insufficient_permissions.role_assignment"))
      expect(user.reload.system_role).to eq('volunteer')
    end

    it 'rejects an admin self-promoting to super_admin' do
      updater = described_class.new(
        user_id: admin.id,
        system_role: 'super_admin',
        updated_by_id: admin.id
      )

      result = updater.call

      expect(result.success?).to be(false)
      expect(result.message).to include(I18n.t("services.errors.insufficient_permissions.role_assignment"))
      expect(admin.reload.system_role).to eq('admin')
    end

    it 'does not block resubmitting the target user\'s current role unchanged' do
      admin_target = create(:user, :admin)

      updater = described_class.new(
        user_id: admin_target.id,
        system_role: 'admin', # inchangé — un admin (non super_admin) ne pourrait pas l'assigner à nouveau
        email_address: 'still.admin@example.com',
        updated_by_id: admin.id
      )

      result = updater.call

      expect(result.success?).to be(true)
      expect(admin_target.reload.email_address).to eq('still.admin@example.com')
    end

    it 'allows a super_admin to assign the admin role' do
      super_admin = create(:user, :super_admin)

      updater = described_class.new(
        user_id: user.id, # volunteer
        system_role: 'admin',
        updated_by_id: super_admin.id
      )

      result = updater.call

      expect(result.success?).to be(true)
      expect(user.reload.system_role).to eq('admin')
    end
  end
end
